import SnapshotTesting
import SwiftUI
import Testing

@testable import Home

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff), .everyLookPainted)
struct WardrobeSnapshotTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func bramblesWardrobe(scheme: ColorScheme) {
    expectSnapshot(of: WardrobePreview(), scheme: scheme)
  }

  @Test func haresWardrobe() {
    expectSnapshot(of: WardrobePreview(friend: .hare), scheme: .light)
  }
}
