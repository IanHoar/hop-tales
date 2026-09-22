import ComposableArchitecture2
import Content
import DesignSystem
import SwiftUI

#if DEBUG
struct HomePreview: View {
  enum Variant {
    case firstRun
    case midway
  }

  let variant: Variant

  init(_ variant: Variant) {
    self.variant = variant
  }

  var body: some View {
    HomeScreen(store: Store(initialState: state) { Home() })
      .frame(width: Metrics.phone.reference.width, height: Metrics.phone.reference.height)
  }

  private var state: Home.State {
    switch variant {
    case .firstRun:
      return Home.State()
    case .midway:
      var state = Home.State(childName: "Wren")
      state.progress = Content.Progress(
        stars: 56,
        completedSentences: ["meadow-morning": 6, "castle-road": 3]
      )
      return state
    }
  }
}

#Preview("First run") { HomePreview(.firstRun) }
#Preview("Midway") { HomePreview(.midway) }
#endif
