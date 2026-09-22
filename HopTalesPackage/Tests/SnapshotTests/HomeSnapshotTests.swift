import SnapshotTesting
import SwiftUI
import Testing

@testable import Home

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff))
struct HomeSnapshotTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func firstRun(scheme: ColorScheme) {
    expectSnapshot(of: HomePreview(.firstRun), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func midway(scheme: ColorScheme) {
    expectSnapshot(of: HomePreview(.midway), scheme: scheme)
  }
}
