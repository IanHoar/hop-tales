import ComposableArchitecture2
import Content
import Dependencies
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
    public init() {}
  }

  public enum Action {
    case home(Home.Action)
    case onboarding(Onboarding.Action)
    case path(Path.State.ID, Path.Action)
  }

  @Dependency(ProfileStore.self) var profileStore

  public var body: some Feature {
    Features {
      Update { state, action in
        switch action {
        case let .home(.storyTapped(story)):
          state.path.append(.reading(Reading.State(story: story)))
        case .home(.grownUpsTapped), .home(.playOnTVTapped):
          break
        case let .onboarding(.finished(profile)):
          profileStore.save(profile)
          state.home.apply(profile)
          state.onboarding = nil
        case .onboarding:
          break
        case .path(_, .reading(.backToStoriesTapped)):
          state.path.removeLast()
        case .path:
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
    .onMount { state in
      guard let profile = profileStore.load() else {
        state.onboarding = profileStore.loadDraft().map(Onboarding.State.init(resuming:))
          ?? Onboarding.State()
        return
      }
      state.home.apply(profile)
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
  }
}

#Preview {
  RootScreen(store: Store(initialState: Root.State()) { Root() })
}
