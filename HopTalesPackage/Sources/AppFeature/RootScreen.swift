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
    public var onboarding: Onboarding.State?
    public var path: [Path.State] = []
    public var settings: Settings.State?
    public init() {}

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
  }

  @Dependency(ProfileStore.self) var profileStore

  public var body: some Feature {
    Features {
      Update { state, action in
        switch action {
        case let .home(.storyTapped(story)):
          state.path.append(.reading(Reading.State(story: story)))
        case .home(.grownUpsTapped):
          state.settings = Settings.State()
        case .settings(.doneTapped):
          state.settings = nil
          if let profile = profileStore.load() { state.home.apply(profile) }
        case .home(.playOnTVTapped):
          break
        case let .onboarding(.finished(profile)):
          profileStore.save(profile)
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
        case .path(_, .reading(.backToStoriesTapped)):
          state.path.removeLast()
        case .path, .settings:
          break
        }
      }
      Scope(\.home) {
        Home()
      }
    }
    .ifLet(\.onboarding) {
      Onboarding()
    }
    .ifLet(\.settings) {
      Settings()
    }
    .onMount { state in
      if let profile = profileStore.load() {
        state.home.apply(profile)
        return
      }
      let resumed = profileStore.loadDraft().map(Onboarding.State.init(resuming:))
      guard let resumed, resumed.isComplete else {
        state.onboarding = resumed ?? Onboarding.State()
        return
      }
      profileStore.save(resumed.profile)
      state.home.apply(resumed.profile)
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

  public var body: some View {
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
  }
}

#Preview {
  RootScreen(store: Store(initialState: Root.State()) { Root() })
}
