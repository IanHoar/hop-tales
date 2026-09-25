import ComposableArchitecture2
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
    case path(Path.State.ID, Path.Action)
    case settings(Settings.Action)
    case journeyMap(JourneyMap.Action)
    case wardrobe(Wardrobe.Action)
    case friends(Friends.Action)
    case book(Book.Action)
  }

  @Dependency(ProfileStore.self) var profileStore
  @Dependency(ProgressStore.self) var progressStore

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
          let reading = Reading.State(story, on: progressStore.load().journey)
          state.path.append(.reading(reading))
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
          let reading = Reading.State(story, on: progressStore.load().journey)
          state.path.append(.reading(reading))
        case .journeyMap:
          break
        case .home(.grownUpsTapped):
          state.settings = Settings.State()
        case .settings(.doneTapped):
          state.settings = nil
          if let profile = profileStore.load() { state.home.apply(profile) }
          state.home.apply(progressStore.load())
        case .home(.playOnTVTapped):
          break
        case .intro(.finished):
          state.intro = nil
        case .intro:
          break
        case let .onboarding(.finished(profile)):
          profileStore.save(profile)
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
          state.home = Home.State()
          state.onboarding = Onboarding.State()
        case let .path(_, .reading(.continueTapped(story))):
          state.path.removeLast()
          let reading = Reading.State(story, on: progressStore.load().journey)
          state.path.append(.reading(reading))
          state.home.apply(progressStore.load())
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
        startJourney(with: profile.startingFriend)
        state.home.apply(profile)
        state.home.apply(progressStore.load())
        return
      }
      let resumed = profileStore.loadDraft().map(Onboarding.State.init(resuming:))
      guard let resumed, resumed.isComplete else {
        state.onboarding = resumed ?? Onboarding.State()
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

  public var body: some View {
    ZStack {
      destination
        .offset(y: store.intro == nil || reduceMotion ? 0 : 80)
        .opacity(store.intro == nil ? 1 : 0)
      if let intro = store.scope(\.intro) {
        IntroScreen(store: intro)
          .transition(.opacity)
          .zIndex(1)
      }
    }
    .animation(handover, value: store.intro == nil)
  }

  private var handover: Animation {
    reduceMotion ? .easeInOut(duration: 0.3) : .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.7)
  }

  private var destination: some View {
    Group {
      if let onboarding = store.scope(\.onboarding) {
        OnboardingScreen(store: onboarding)
          .transition(.opacity)
      } else {
        stories
      }
    }
    .animation(.easeInOut(duration: 0.3), value: store.onboarding == nil)
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
  init(_ story: Story, on journey: Journey) {
    self.init(
      story: story,
      friend: journey.activeFriend,
      bigWords: journey.bigWords(in: story),
      treat: journey.treat(in: story)
    )
  }
}
