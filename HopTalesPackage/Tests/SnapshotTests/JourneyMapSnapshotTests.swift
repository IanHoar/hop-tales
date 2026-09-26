import SnapshotTesting
import SwiftUI
import Testing

@testable import Home

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff))
struct JourneyMapSnapshotTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func theJourneyFromBobToBartholomew(scheme: ColorScheme) {
    expectSnapshot(of: JourneyMapPreview(), scheme: scheme)
  }
}
