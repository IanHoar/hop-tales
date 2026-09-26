import Content
import SnapshotTesting
import SwiftUI
import Testing

@testable import Reading

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff), .everyLookPainted)
struct StoryPropSnapshotTests {
  @Test(arguments: [
    ("meadow-walk", 3, 2), ("golden-hour", 3, 2), ("oggy-kite", 1, 3),
    ("rain-on-the-field", 3, 2), ("bartholomew-journey", 0, 8), ("bartholomew-fiddle", 1, 2)
  ])
  func propsRestBesideThePath(story id: String, sentence: Int, word: Int) throws {
    let story = try #require(StoryLibrary[id])
    expectSnapshot(
      of: ReadingScreenPreview(
        story: story, moment: .at(sentence: sentence, word: word), friend: story.friend
      )
      .environment(\.freezesMotion, true),
      as: .image(
        layout: .device(config: ReadingScreenSnapshotTests.device(
          ReadingScreenSnapshotTests.smallPhone, .light
        ))
      ),
      named: id
    )
  }
}
