import SnapshotTesting
import SwiftUI
import Testing

@testable import Reading

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff))
struct MicPillSnapshotTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func listening(scheme: ColorScheme) {
    expectSnapshot(of: MicPillPreview(.listening), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func heardAWord(scheme: ColorScheme) {
    expectSnapshot(of: MicPillPreview(.heard), scheme: scheme)
  }
}
