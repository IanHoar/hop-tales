import SnapshotTesting
import SwiftUI
import Testing

@testable import GrownUps
@testable import Reading

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff))
struct GrownUpsSnapshotTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func everySetting(scheme: ColorScheme) {
    expectSnapshot(of: SettingsPreview(height: 1320), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func stoppingAStoryAsksFirst(scheme: ColorScheme) {
    expectSnapshot(of: StopReadingPreview(), scheme: scheme)
  }
}
