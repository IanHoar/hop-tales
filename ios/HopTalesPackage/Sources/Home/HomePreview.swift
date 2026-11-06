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
    case plusPathFull
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
    state.locksStories = [.locked, .lockedLevels, .plusPathFull].contains(variant)
    state.isPlus = variant == .plusPathFull
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
    case .plusPathFull:
      Self.everyLevelOneStoryRead
    }
  }

  private static var everyLevelOneStoryRead: Content.Progress {
    let stories = StoryLibrary.stories(at: 1)
    var progress = Content.Progress(
      stars: 40,
      completedSentences: Dictionary(uniqueKeysWithValues: stories.map { ($0.id, 99) })
    )
    progress.journey.storiesRead = Set(stories.map(\.id))
    return progress
  }
}

#Preview("First run") { HomePreview(.firstRun) }
#Preview("Midway") { HomePreview(.midway) }
#Preview("Locked stories") { HomePreview(.locked) }
#Preview("Locked levels") { HomePreview(.lockedLevels, size: HomePreview.tallPhone) }
#Preview("Plus, big story ready") { HomePreview(.plusPathFull, size: HomePreview.tallPhone) }
#Preview("iPad") { HomePreview(.midway, size: Metrics.pad.reference) }
#endif
