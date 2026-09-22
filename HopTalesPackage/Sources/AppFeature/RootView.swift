import ComposableArchitecture2
import Home
import Reading
import SwiftUI

public struct RootView: View {
  @Bindable var store: StoreOf<Root>

  public init(store: StoreOf<Root>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack(path: $store.scope(\.path)) {
      HomeView(store: store.scope(\.home))
        .navigationDestination(for: Path.StoreEnumeration.self) { pathStore in
          switch pathStore {
          case let .reading(readingStore):
            ReadingView(store: readingStore)
          }
        }
    }
  }
}

#Preview {
  RootView(store: Store(initialState: Root.State()) { Root() })
}
