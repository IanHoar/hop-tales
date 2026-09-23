import ComposableArchitecture2
import DesignSystem
import SwiftUI

struct ReadingPanels: ViewModifier {
  let store: StoreOf<Reading>

  func body(content: Content) -> some View {
    content
      .overlay {
        if let authorization = store.authorization, authorization != .authorized {
          ListeningUnavailable(authorization: authorization) {
            store.send(.backToStoriesTapped)
          }
          .transition(.opacity)
        }
      }
      .overlay {
        if case let .story(stars) = store.completed {
          StoryFinished(title: store.story.title, stars: stars) {
            store.send(.backToStoriesTapped)
          }
          .transition(.opacity)
        }
      }
      .overlay {
        if store.isConfirmingStop {
          StopReading {
            store.send(.keepReadingTapped)
          } stop: {
            store.send(.backToStoriesTapped)
          }
          .transition(.opacity)
        }
      }
      .animation(Motion.recognised, value: store.completed)
      .animation(.easeInOut(duration: 0.2), value: store.isConfirmingStop)
  }
}
