import ComposableArchitecture2
import Content
import Home
import Reading

@Feature public enum Path {
  case reading(Reading)
}

/// The app's root: home, plus a stack of destinations.
@Feature public struct Root {
  public init() {}

  public struct State {
    public var home = Home.State()
    public var path: [Path.State] = []

    public init() {}
  }

  public enum Action {
    case home(Home.Action)
    case path(Path.State.ID, Path.Action)
  }

  public var body: some Feature {
    Features {
      Update { state, action in
        switch action {
        case let .home(.storyTapped(story)):
          state.path.append(.reading(Reading.State(story: story)))
        case .path:
          break
        }
      }
      Scope(\.home) {
        Home()
      }
    }
    .forEach(\.path, dismissStyle: .stack) {
      Path.body
    }
  }
}
