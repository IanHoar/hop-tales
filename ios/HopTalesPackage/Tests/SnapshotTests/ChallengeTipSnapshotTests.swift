import SnapshotTesting
import SwiftUI
import Testing

@testable import Reading

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff))
struct ChallengeTipSnapshotTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func aChallengeWordExplainsItself(scheme: ColorScheme) {
    expectSnapshot(of: ChallengeTipPreview(), scheme: scheme)
  }
}
