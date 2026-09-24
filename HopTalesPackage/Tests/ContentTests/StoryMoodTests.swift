import Testing

@testable import Content

struct StoryMoodTests {
  @Test func everyStoryDecodesWithAMood() {
    #expect(StoryLibrary.all.count == 4)
    #expect(StoryLibrary.all.allSatisfy { !$0.sentences.isEmpty })
  }

  @Test func aSentenceChangesOnlyWhatItNames() {
    let story = Story(
      id: "test",
      title: "Test",
      sentences: [
        Sentence(words: [Word(text: "a")]),
        Sentence(words: [Word(text: "b")], weather: .storm),
        Sentence(words: [Word(text: "c")], sky: .night),
        Sentence(words: [Word(text: "d")])
      ],
      mood: Mood(sky: .day, weather: .clear)
    )
    #expect(story.mood(atSentence: 0) == Mood(sky: .day, weather: .clear))
    #expect(story.mood(atSentence: 1) == Mood(sky: .day, weather: .storm))
    #expect(story.mood(atSentence: 2) == Mood(sky: .night, weather: .storm))
    #expect(story.mood(atSentence: 3) == Mood(sky: .night, weather: .storm))
    #expect(story.finalMood == Mood(sky: .night, weather: .storm))
  }

  @Test func theStoriesTravelThroughTheirMoods() {
    #expect(StoryLibrary["moonlight-hop"]?.finalMood.sky == .night)
    #expect(StoryLibrary["storm-on-the-hill"]?.mood(atSentence: 2).weather == .rain)
    #expect(StoryLibrary["golden-hour"]?.finalMood.sky == .golden)
  }
}
