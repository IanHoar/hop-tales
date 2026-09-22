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
      $0.stars = 1
      $0.wordIndex = 1
    }

    await store.dismount()
  }

  @Test func finishingASentenceWithNoHelpAwardsFiveMoreStars() {
    var state = Reading.State(story: StoryLibrary.all[0])
    let words = state.sentence!.words.count
    state.advance(by: words)
    #expect(state.sentenceIndex == 1)
    #expect(state.wordIndex == 0)
    #expect(state.stars == words + 5)
  }

  @Test func worldProgressTraversesTheWorldExactlyOnce() {
    var state = Reading.State(story: StoryLibrary.all[0])
    for sentence in state.story.sentences {
      state.advance(by: sentence.words.count)
    }
    #expect(state.worldProgress == 1950)
  }
}
