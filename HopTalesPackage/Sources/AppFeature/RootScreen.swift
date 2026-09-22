import ComposableArchitecture2
import Content
import Home
import Reading
import SwiftUI

@Feature public enum Path {
  case reading(Reading)
}

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
        case .home(.grownUpsTapped), .home(.playOnTVTapped):
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
