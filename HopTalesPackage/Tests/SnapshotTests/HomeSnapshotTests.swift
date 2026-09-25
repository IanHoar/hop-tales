import DesignSystem
import SnapshotTesting
import SwiftUI
import Testing

@testable import Home

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff), .everyLookPainted)
struct HomeSnapshotTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func firstRun(scheme: ColorScheme) {
    expectSnapshot(of: HomePreview(.firstRun), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func midway(scheme: ColorScheme) {
    expectSnapshot(of: HomePreview(.midway), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func midwayOnAnIPad(scheme: ColorScheme) {
    expectSnapshot(of: HomePreview(.midway, size: Metrics.pad.reference), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func midwayOnAnIPadInPortrait(scheme: ColorScheme) {
    let portrait = CGSize(width: Metrics.pad.reference.height, height: Metrics.pad.reference.width)
    expectSnapshot(of: HomePreview(.midway, size: portrait), scheme: scheme)
  }
}
