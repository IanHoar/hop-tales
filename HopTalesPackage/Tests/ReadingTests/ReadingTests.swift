import ComposableArchitecture2
import Content
import Testing

@testable import Reading
@MainActor
struct ReadingTests {
  @Test func readingAWordAdvancesTheBallAndAwardsAStar() async {
    let store = TestStore(initialState: Reading.State(story: StoryLibrary.all[0])) {
      Reading()
    }

    await store.send(.speechResult(tokens: ["the"], isFinal: false))
    await store.send(.speechResult(tokens: ["the"], isFinal: false)) {
      $0.heardToken = "the"
      $0.recognised = Reading.State.Recognised(
        count: 1,
        sentenceIndex: 0,
        stars: 1,
        wordIndex: 0
      )
      $0.stars = 1
      $0.wordIndex = 1
    }

    await store.dismount()
  }

  @Test func theLastWordOfASentenceCarriesTheBonusIntoTheChip() {
    var state = Reading.State(story: StoryLibrary.all[0])
    let words = state.sentence!.words.count
    state.advance(by: words - 1)
    let before = state.stars
    state.advance(by: 1)
    #expect(state.stars - before == 6)
  }

  @Test func finishingASentenceWithNoHelpAwardsFiveMoreStars() {
    var state = Reading.State(story: StoryLibrary.all[0])
    let words = state.sentence!.words.count
    state.advance(by: words)
    #expect(state.sentenceIndex == 1)
    #expect(state.wordIndex == 0)
    #expect(state.stars == words + 5)
  }

  @Test func finishingASentenceRecordsWhichOne() {
    var state = Reading.State(story: StoryLibrary.all[0])
    state.advance(by: state.sentence!.words.count)
    #expect(state.completed == .sentence(index: 0))
    #expect(state.completionCount == 1)
  }

  @Test func finishingTheLastSentenceEndsTheStoryInstead() {
    var state = Reading.State(story: StoryLibrary.all[0])
    for sentence in state.story.sentences {
      state.advance(by: sentence.words.count)
    }
    #expect(state.completed == .story(stars: state.stars))
    #expect(state.completionCount == state.story.sentences.count)
  }

  @Test func worldProgressTraversesTheWorldExactlyOnce() {
    var state = Reading.State(story: StoryLibrary.all[0])
    for sentence in state.story.sentences {
      state.advance(by: sentence.words.count)
    }
    #expect(state.worldProgress == 1950)
  }
}
