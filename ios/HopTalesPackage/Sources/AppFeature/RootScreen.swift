import ComposableArchitecture
import Content
import Dependencies
import DesignSystem
import GrownUps
import Home
import Onboarding
import Reading
import SwiftUI

@Feature public enum Path {
  case reading(Reading)
}

@Feature public struct Root {
  public init() {}

  public struct State {
    public var home = Home.State()
    public var intro: Intro.State? = Intro.State()
    public var onboarding: Onboarding.State?
    public var plusOffer: GrownUpPaywall.State?
    public var path: [Path.State] = []
    public var settings: Settings.State?
    public var journeyMap: JourneyMap.State?
    public var wardrobe: Wardrobe.State?
    public var friends: Friends.State?
    public var book: Book.State?
    public var theme = Profile.Theme.device
    public init() {}

    public var storyOnScreen: Story? {
      guard case let .reading(reading) = path.last else { return nil }
      return reading.story
    }
  }

  public enum Action {
    case home(Home.Action)
    case intro(Intro.Action)
    case onboarding(Onboarding.Action)
    case plusOffer(GrownUpPaywall.Action)
    case path(Path.State.ID, Path.Action)
    case settings(Settings.Action)
    case journeyMap(JourneyMap.Action)
    case wardrobe(Wardrobe.Action)
    case friends(Friends.Action)
    case book(Book.Action)
  }

  @Dependency(ProfileStore.self) var profileStore
  @Dependency(ProgressStore.self) var progressStore
  @Dependency(GateSeed.self) var gateSeed

  private func open(_ story: Story, _ state: inout State) {
    guard !state.home.isLocked(story) else {
      state.home.showLocked(story)
      return
    }
    var reading = Reading.State(story, on: progressStore.load())
    reading.isPlus = state.home.isPlus
    reading.locksStories = state.home.locksStories
    state.path.append(.reading(reading))
  }

  private func startJourney(with friend: Friend) {
    var progress = progressStore.load()
    guard progress.journey.level < friend.level else { return }
    progress.journey = Journey(starting: friend)
    progressStore.save(progress)
  }

  public var body: some Feature {
    Features {
      Update { state, action in
        switch action {
        case let .home(.storyTapped(story)):
          open(story, &state)
        case .home(.friendsTapped):
          state.friends = Friends.State()
        case .home(.bookTapped):
          state.book = Book.State(friend: progressStore.load().journey.activeFriend)
        case .friends(.journeyTapped):
          state.friends = nil
          state.journeyMap = JourneyMap.State()
        case .friends(.doneTapped):
          state.friends = nil
          state.home.apply(progressStore.load())
        case .book(.doneTapped):
          state.book = nil
        case .friends, .book:
          break
        case .home(.wardrobeTapped):
          state.wardrobe = Wardrobe.State(friend: progressStore.load().journey.activeFriend)
        case let .path(_, .reading(.tryItOnTapped(friend))):
          var progress = progressStore.load()
          if let item = progress.newestItem(for: friend) {
            progress.wear(item, on: friend)
            progressStore.save(progress)
          }
          state.wardrobe = Wardrobe.State(friend: friend)
        case .wardrobe(.doneTapped):
          state.wardrobe = nil
          state.home.apply(progressStore.load())
        case .wardrobe:
          break
        case .home(.journeyTapped):
          state.journeyMap = JourneyMap.State()
        case .journeyMap(.doneTapped):
          state.journeyMap = nil
          state.home.apply(progressStore.load())
        case let .journeyMap(.bigStoryTapped(story)):
          state.journeyMap = nil
          open(story, &state)
        case .journeyMap:
          break
        case .home(.grownUpsTapped):
          state.settings = Settings.State()
        case .settings(.doneTapped):
          state.settings = nil
          if let profile = profileStore.load() { state.home.apply(profile) }
          state.home.apply(progressStore.load())
        case let .settings(.themePicked(theme)):
          state.theme = theme
        case .home(.plusChanged(true)):
          state.plusOffer = nil
        case .home(.grownUp), .home(.locked), .home(.lockedLevelTapped), .home(.plusChanged):
          break
        case .intro(.finished):
          state.intro = nil
        case .intro:
          break
        case let .onboarding(.finished(answered)):
          var profile = profileStore.load() ?? answered
          let offersPlus = Plus.offersAtOnboarding(
            profile, isPlus: state.home.isPlus, locksStories: state.home.locksStories
          )
          if offersPlus { profile.plusOffered = true }
          profileStore.save(profile)
          state.theme = profile.theme
          startJourney(with: profile.startingFriend)
          state.home.apply(progressStore.load())
          state.home.apply(profile)
          state.onboarding = nil
          if offersPlus {
            state.plusOffer = GrownUpPaywall.State(seed: gateSeed.draw(), isOnboarding: true)
          }
        case .onboarding:
          break
        case .plusOffer(.paywall(.subscribed)):
          state.plusOffer = nil
          state.home.isPlus = true
        case .plusOffer(.gate(.closeTapped)), .plusOffer(.paywall(.closeTapped)),
          .plusOffer(.paywall(.tryLevelOneTapped)):
          state.plusOffer = nil
        case .plusOffer:
          break
        case .settings(.resetOnboardingTapped):
          profileStore.erase()
          state.settings = nil
          state.path = []
          var home = Home.State()
          home.isPlus = state.home.isPlus
          home.locksStories = state.home.locksStories
          state.home = home
          state.plusOffer = nil
          state.onboarding = Onboarding.State(welcoming: true)
        case .path(_, .reading(.backToStoriesTapped)):
          state.path.removeLast()
          state.home.apply(progressStore.load())
        case .path, .settings:
          break
        }
      }
      Scope(\.home) {
        Home()
      }
    }
    .ifLet(\.intro) {
      Intro()
    }
    .ifLet(\.onboarding) {
      Onboarding()
    }
    .ifLet(\.plusOffer) {
      GrownUpPaywall()
    }
    .ifLet(\.settings) {
      Settings()
    }
    .ifLet(\.journeyMap) {
      JourneyMap()
    }
    .ifLet(\.wardrobe) {
      Wardrobe()
    }
    .ifLet(\.friends) {
      Friends()
    }
    .ifLet(\.book) {
      Book()
    }
    .onMount { state in
      if let profile = profileStore.load() {
        state.theme = profile.theme
        startJourney(with: profile.startingFriend)
        state.home.apply(profile)
        state.home.apply(progressStore.load())
        return
      }
      let resumed = profileStore.loadDraft().map(Onboarding.State.init(resuming:))
      guard let resumed, resumed.isComplete else {
        state.onboarding = resumed ?? Onboarding.State(welcoming: true)
        return
      }
      profileStore.save(resumed.profile)
      startJourney(with: resumed.profile.startingFriend)
      state.home.apply(resumed.profile)
      state.home.apply(progressStore.load())
    }
    .forEach(\.path, dismissStyle: .stack) {
      Path.body
    }
  }
}

public struct RootScreen: View {
  @Bindable var store: StoreOf<Root>

  public init(store: StoreOf<Root>) {
    self.store = store
  }

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var onboarded = false

  public var body: some View {
    ZStack {
      destination
        .animation(handover) { content in
          content
            .offset(y: store.intro == nil || reduceMotion ? 0 : 80)
            .opacity(store.intro == nil ? 1 : 0)
        }
        .accessibilityHidden(store.intro != nil)
      if let intro = store.scope(\.intro) {
        IntroScreen(store: intro)
          .transition(.opacity.animation(handover))
          .zIndex(1)
      }
    }
    .background {
      if store.intro != nil { Color(hex: 0x1E2A4E).ignoresSafeArea() }
    }
    .preferredColorScheme(store.intro == nil ? store.theme.colorScheme : .dark)
  }

  private var handover: Animation {
    reduceMotion ? .easeInOut(duration: 0.3) : .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.7)
  }

  private var destination: some View {
    Group {
      if let onboarding = store.scope(\.onboarding) {
        OnboardingScreen(store: onboarding)
          .transition(.opacity.animation(.easeInOut(duration: 0.45)))
          .onAppear { onboarded = true }
      } else {
        stories
          .environment(\.arrivesFromOnboarding, onboarded)
          .transition(.opacity.animation(.easeInOut(duration: 0.45)))
      }
    }
  }

  private var stories: some View {
    NavigationStack(path: $store.scope(\.path)) {
      HomeScreen(store: store.scope(\.home))
        .navigationDestination(for: Path.StoreEnumeration.self) { pathStore in
          switch pathStore {
          case let .reading(readingStore):
            ReadingScreen(store: readingStore)
          }
        }
    }
    .sheet(item: $store.scope(\.settings)) { settings in
      SettingsScreen(store: settings)
        .tint(Palette.ink)
        .interactiveDismissDisabled()
    }
    .sheet(item: $store.scope(\.journeyMap)) { journeyMap in
      JourneyMapScreen(store: journeyMap)
        .interactiveDismissDisabled()
    }
    .sheet(item: $store.scope(\.wardrobe)) { wardrobe in
      WardrobeScreen(store: wardrobe)
        .interactiveDismissDisabled()
    }
    .sheet(item: $store.scope(\.friends)) { friends in
      FriendsScreen(store: friends)
        .interactiveDismissDisabled()
    }
    .sheet(item: $store.scope(\.book)) { book in
      BookScreen(store: book)
        .interactiveDismissDisabled()
    }
    .sheet(item: $store.scope(\.plusOffer)) { plusOffer in
      GrownUpPaywallScreen(store: plusOffer)
        .interactiveDismissDisabled()
    }
  }
}

#Preview {
  RootScreen(store: Store(initialState: Root.State()) { Root() })
}

extension Reading.State {
  init(_ story: Story, on progress: Content.Progress) {
    let journey = progress.journey
    self.init(
      story: story,
      friend: story.friend,
      bigWords: journey.bigWords(in: story),
      treat: journey.treat(in: story)
    )
    look = progress.outfit(for: story.friend).first?.id
  }
}

extension Profile.Theme {
  var colorScheme: ColorScheme? {
    switch self {
    case .device: nil
    case .light: .light
    case .dark: .dark
    }
  }
}
