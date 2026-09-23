import ComposableArchitecture2
import Reading
import SwiftUI

public struct TVScreen: View {
  let store: StoreOf<Root>

  public init(store: StoreOf<Root>) {
    self.store = store
  }

  public var body: some View {
    if store.storyOnScreen != nil,
      let last = store.scope(\.path).last,
      case let .reading(reading) = last.enumeration {
      TVReadingScreen(store: reading)
    } else {
      TVWaitingScreen(childName: store.home.childName)
    }
  }
}
