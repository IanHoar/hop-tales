import ComposableArchitecture2
import Content
import Dependencies
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
    HomeScreen(store: store)
  }

  private var store: StoreOf<Home> {
    let saved = progress
    return withDependencies {
      $0[ProgressStore.self] = ProgressStore(load: { saved }, save: { _ in })
    } operation: {
      Store(initialState: Home.State(childName: variant == .midway ? "Wren" : nil)) { Home() }
    }
  }

  private var progress: Content.Progress {
    switch variant {
    case .firstRun:
      Content.Progress()
    case .midway:
      Content.Progress(
        stars: 56,
        completedSentences: ["meadow-morning": 6, "castle-road": 3]
      )
    }
  }
}

#Preview("First run") { HomePreview(.firstRun) }
#Preview("Midway") { HomePreview(.midway) }
#endif
