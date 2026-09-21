import AppFeature
import ComposableArchitecture2
import SwiftUI

@main
struct WordhopApp: App {
  static let store = Store(initialState: Root.State()) {
    Root()
  }

  var body: some Scene {
    WindowGroup {
      RootView(store: Self.store)
    }
  }
}
