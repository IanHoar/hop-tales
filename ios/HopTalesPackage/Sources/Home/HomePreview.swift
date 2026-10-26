import ComposableArchitecture
import Content
import Dependencies
import DesignSystem
import SwiftUI

#if DEBUG
struct HomePreview: View {
  enum Variant {
    case firstRun
    case midway
    case locked
    case lockedLevels
  }

  static let tallPhone = CGSize(width: Metrics.phone.reference.width, height: 1480)

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
      Store(initialState: state) { Home() }
    }
  }

  private var state: Home.State {
    var state = Home.State(childName: variant == .firstRun ? nil : "Wren")
    state.hour = 9
    state.locksStories = variant == .locked || variant == .lockedLevels
    return state
  }

  private var progress: Content.Progress {
    switch variant {
    case .firstRun:
      Content.Progress()
    case .midway, .locked:
      Content.Progress(
        stars: 56,
        completedSentences: ["meadow-walk": 6, "golden-hour": 3],
        journey: Journey(starting: .hare)
      )
    case .lockedLevels:
      Content.Progress(stars: 30, completedSentences: ["meadow-walk": 6, "bob-bug": 2])
    }
  }
}

#Preview("First run") { HomePreview(.firstRun) }
#Preview("Midway") { HomePreview(.midway) }
#Preview("Locked stories") { HomePreview(.locked) }
#Preview("Locked levels") { HomePreview(.lockedLevels, size: HomePreview.tallPhone) }
#Preview("iPad") { HomePreview(.midway, size: Metrics.pad.reference) }
#endif
