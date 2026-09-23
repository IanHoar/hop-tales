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
  let size: CGSize

  init(_ variant: Variant, size: CGSize = Metrics.phone.reference) {
    self.variant = variant
    self.size = size
  }

  var body: some View {
    HomeScreen(store: store)
      .frame(width: size.width, height: size.height)
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
#Preview("iPad") { HomePreview(.midway, size: Metrics.pad.reference) }
#endif
