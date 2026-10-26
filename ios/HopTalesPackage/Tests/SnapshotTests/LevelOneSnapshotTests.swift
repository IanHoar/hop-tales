import SnapshotTesting
import SwiftUI
import Testing

@testable import Reading

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff), .everyLookPainted)
struct LevelOneSnapshotTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func finishingLevelOneShowsWhatIsNext(scheme: ColorScheme) {
    expectSnapshot(
      of: ReadingScreenPreview(moment: .levelOneFinished)
        .environment(\.freezesMotion, true)
        .environment(\.colorScheme, scheme),
      as: .image(
        layout: .device(config: ReadingScreenSnapshotTests.device(
          ReadingScreenSnapshotTests.smallPhone, scheme
        )),
        traits: snapshotTraits
      ),
      named: "\(scheme)"
    )
  }
}
