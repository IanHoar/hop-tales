import Foundation
import Testing

@testable import Content

struct StoryEventTests {
  @Test func everyEventNamesAKnownProp() {
    for story in StoryLibrary.all {
      for event in story.sentences.flatMap(\.events) {
        #expect(StoryProp.named(event.prop) != nil, "\(story.id): \(event.prop)")
      }
    }
  }

  @Test func everyStoryHasAtLeastTwoMoments() {
    for story in StoryLibrary.all {
      let props = story.sentences.flatMap(\.events).count
      let moods = story.sentences.filter { $0.sky != nil || $0.weather != nil }.count
      #expect(props + moods >= 2, "\(story.id)")
    }
  }

  @Test func aPropComesAfterItsWordAndNeverNamesAWordItAppearsBefore() {
    for story in StoryLibrary.all {
      for sentence in story.sentences {
        let words = sentence.words.map { $0.text.lowercased() }
        for event in sentence.events {
          if let after = event.after {
            #expect(words.indices.contains(after), "\(story.id): \(event.prop)")
          } else {
            #expect(!words.contains(event.prop), "\(story.id): \(event.prop) gives it away")
          }
        }
      }
    }
  }

  @Test func aSentenceWithoutEventsDecodesFromOlderJSON() throws {
    let json = Data(#"{"words": [{"text": "sun", "homophones": [], "big": false}]}"#.utf8)
    #expect(try JSONDecoder().decode(Sentence.self, from: json).events.isEmpty)
  }
}
