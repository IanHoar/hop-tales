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
    public var path: [Path.State] = []
    public var settings: Settings.State?
    public var journeyMap: JourneyMap.State?
    public var wardrobe: Wardrobe.State?
    public var friends: Friends.State?
    public var book: Book.State?
    public var theme = Profile.Theme.device
    public var arrivesFromOnboarding = false
    public init() {}

    public var screensOverHome: Int {
      path.count
        + [settings != nil, journeyMap != nil, wardrobe != nil, friends != nil, book != nil]
        .filter { $0 }.count
    }

    public var storyOnScreen: Story? {
      guard case let .reading(reading) = path.last else { return nil }
      return reading.story
    }
  }

  public enum Action {
    case home(Home.Action)
    case onboarding(Onboarding.Action)
    case path(Path.State.ID, Path.Action)
    case settings(Settings.Action)
    case friends(Friends.Action)
  }

  @Dependency(\.locale) var locale
  @Dependency(ProfileStore.self) var profileStore
  @Dependency(ProgressStore.self) var progressStore

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
        case .friends:
          break
        case .home(.wardrobeTapped):
          state.wardrobe = Wardrobe.State(friend: progressStore.load().journey.activeFriend)
        case .home(.journeyTapped):
          state.journeyMap = JourneyMap.State()
        case .home(.grownUpsTapped):
          state.settings = Settings.State()
        case let .settings(.themePicked(theme)):
          state.theme = theme
        case .home(.grownUp), .home(.locked), .home(.levelTapped), .home(.plusChanged):
          break
        case let .onboarding(.finished(answered)):
          let profile = profileStore.load() ?? answered
          profileStore.save(profile)
          state.theme = profile.theme
          startJourney(with: profile.startingFriend)
          state.home.apply(progressStore.load())
          state.home.apply(profile)
          state.onboarding = nil
        case .onboarding:
          break
        case .settings(.resetOnboardingTapped):
          profileStore.erase()
          state.settings = nil
          state.path = []
          var home = Home.State()
          home.isPlus = state.home.isPlus
          home.locksStories = state.home.locksStories
          state.home = home
          state.onboarding = Onboarding.State(welcoming: true)
          state.arrivesFromOnboarding = true
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
        state.arrivesFromOnboarding = true
        return
      }
      let profile = resumed.profile(region: locale.region)
      profileStore.save(profile)
      startJourney(with: profile.startingFriend)
      state.home.apply(profile)
      state.home.apply(progressStore.load())
    }
    .forEach(\.path, dismissStyle: .stack) {
      Path.body
    }
    .onEvent(TryingItOn.self) { trying, state in
      state.wardrobe = Wardrobe.State(friend: trying.friend, wearsNewest: true)
    }
    .onEvent(StoryChosen.self) { chosen, state in
      state.journeyMap = nil
      open(chosen.story, &state)
    }
    .onChange(of: store.screensOverHome) { old, new, state in
      guard new < old, state.onboarding == nil else { return }
      if let profile = profileStore.load() { state.home.apply(profile) }
      let progress = progressStore.load()
      state.home.apply(progress)
      for index in state.path.indices {
        try? state.path[index].modify(\.reading) {
          $0.look = progress.outfit(for: $0.friend).first?.id
        }
      }
    }
  }
}

public struct RootScreen: View {
  @Bindable var store: StoreOf<Root>

  public init(store: StoreOf<Root>) {
    self.store = store
  }

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
      } else {
        stories
          .environment(\.arrivesFromOnboarding, store.arrivesFromOnboarding)
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
