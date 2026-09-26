import Foundation
import Testing

@testable import Content

struct PhonicsTests {
  let phonics = Phonics.shared

  @Test(arguments: [
    ("sat", 1), ("cats", 1), ("the", 1), ("frog", 2), ("ship", 2), ("ducks", 2),
    ("lake", 3), ("homes", 3), ("dance", 3), ("jumped", 4), ("hopping", 4), ("farm", 4),
    ("rabbit", 4), ("rain", 5), ("house", 5), ("bounced", 5), ("tiny", 6), ("climbing", 6),
    ("wedged", 6), ("little", 6), ("station", 7), ("enormous", 7), ("Bartholomew", 1)
  ])
  func wordsDecodeAtTheLevelThatTeachesThem(word: String, level: Int) {
    #expect(phonics.level(of: word) == level)
  }

  @Test func everyStoryDecodesAtItsLevel() {
    for story in StoryLibrary.all {
      for word in story.sentences.flatMap(\.words) {
        let ceiling = word.big ? min(story.level + 2, Levels.top) : story.level
        let level = phonics.level(of: word.text)
        let note = "\(story.id): \(word.text) decodes at \(level ?? 0)"
        #expect(level.map { $0 <= ceiling } == true, Comment(rawValue: note))
      }
    }
  }

  @Test(arguments: 2...7)
  func eachLevelPractisesItsNewPatterns(level: Int) {
    let words = StoryLibrary.all.filter { $0.level == level }
      .flatMap(\.sentences).flatMap(\.words).filter { !$0.big }
    #expect(words.contains { phonics.level(of: $0.text) == level })
  }

  @Test func sentenceLengthsFitTheTable() {
    for story in StoryLibrary.all {
      let range = Levels.sentenceWords[story.level]
      for sentence in story.sentences {
        let note = "\(story.id): \(sentence.words.count) words"
        #expect(range?.contains(sentence.words.count) == true, Comment(rawValue: note))
      }
    }
  }

  @Test func eachFriendIsNamedForTheTableAndTheirExamplesAreTheirLevel() {
    #expect(phonics.names == Friend.allCases.map(\.name))
    for friend in Friend.allCases {
      #expect(friend.stage == phonics.phase(at: friend.level))
      for word in friend.examples {
        #expect(phonics.level(of: word) == friend.level, "\(friend.name): \(word)")
      }
    }
  }
}
