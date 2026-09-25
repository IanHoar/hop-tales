import SnapshotTesting
import SwiftUI
import Testing

@testable import Home

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff))
struct FriendsSnapshotTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func theFriendsInLevelOrder(scheme: ColorScheme) {
    expectSnapshot(of: FriendsPreview(), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func haresPageInTheCollectionBook(scheme: ColorScheme) {
    expectSnapshot(of: BookPreview(), scheme: scheme)
  }
}
