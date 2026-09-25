import Content
import SnapshotTesting
import SwiftUI
import Testing

@testable import Reading

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff))
struct PathSnapshotTests {
  @Test(arguments: [
    ReadingScreenPreview.Moment.start, .midPage, .nearTheEnd, .end, .bigStoryReady, .newFriend,
    .basketFull
  ])
  func theWordsLieOnThePath(moment: ReadingScreenPreview.Moment) {
    expectSnapshot(
      of: ReadingScreenPreview(moment: moment).environment(\.freezesMotion, true),
      as: .image(
        layout: .device(config: ReadingScreenSnapshotTests.device(
          ReadingScreenSnapshotTests.smallPhone, .light
        ))
      ),
      named: "\(moment)"
    )
  }

  @Test(arguments: [Friend.bunny])
  func eachFriendReadsInTheirOwnWorld(friend: Friend) {
    expectSnapshot(
      of: ReadingScreenPreview(moment: .midPage, friend: friend)
        .environment(\.freezesMotion, true),
      as: .image(
        layout: .device(config: ReadingScreenSnapshotTests.device(
          ReadingScreenSnapshotTests.smallPhone, .light
        ))
      ),
      named: "\(friend)"
    )
  }
}
