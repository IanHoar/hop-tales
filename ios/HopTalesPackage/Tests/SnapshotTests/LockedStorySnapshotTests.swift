import SnapshotTesting
import SwiftUI
import Testing

@testable import GrownUps
@testable import Home

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff))
struct LockedStorySnapshotTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func theCardShowsTheStanding(scheme: ColorScheme) {
    expectSnapshot(of: LockedStoryPreview(), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func theGateAsksATimesTable(scheme: ColorScheme) {
    expectSnapshot(of: ParentGatePreview(), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func theGateDrawsANewQuestion(scheme: ColorScheme) {
    expectSnapshot(of: ParentGatePreview(entry: "4", round: 1), scheme: scheme)
  }
}
