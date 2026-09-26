import Content
import SnapshotTesting
import SwiftUI
import Testing

@testable import Reading

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff), .everyLookPainted)
struct PathSnapshotTests {
  @Test(arguments: [
    ReadingScreenPreview.Moment.start, .midPage, .nearTheEnd, .end, .bigStoryReady, .newFriend,
    .basketFull, .triedItOn
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

  @Test(arguments: [("meadow-walk", 0, 1), ("golden-hour", 3, 1), ("storm-on-the-hill", 3, 2)])
  func soundButtonsSitUnderTheWords(story id: String, sentence: Int, word: Int) throws {
    let story = try #require(StoryLibrary[id])
    expectSnapshot(
      of: ReadingScreenPreview(
        story: story, moment: .at(sentence: sentence, word: word), soundButtons: true
      )
      .environment(\.freezesMotion, true),
      as: .image(
        layout: .device(config: ReadingScreenSnapshotTests.device(
          ReadingScreenSnapshotTests.smallPhone, .light
        ))
      ),
      named: "sound-buttons-\(id)"
    )
  }

  @Test(arguments: [Friend.bunny, .frog, .crow, .cat, .crab, .grasshopper])
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
