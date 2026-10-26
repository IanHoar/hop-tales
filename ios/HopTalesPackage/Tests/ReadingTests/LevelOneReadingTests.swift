import ComposableArchitecture
import Content
import Testing

@testable import Reading

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct LevelOneReadingTests {
  private static func levelOneFinished(then moments: [JourneyMoment] = []) -> Reading.State {
    var state = Reading.State(story: StoryLibrary.all[0])
    state.isActive = false
    state.sentenceIndex = state.story.sentences.count
    state.completed = .story(stars: 30)
    state.journeyMoments = [.levelOneFinished] + moments
    return state
  }

  @Test func backToMyStoriesAfterLevelOneGoesBackToTheStories() async {
    let store = TestStore(initialState: Self.levelOneFinished()) { Reading() }

    store.send(.backToMyStoriesTapped) {
      $0.journeyMoments = []
    }
    await store.receive(\.backToStoriesTapped)
    await store.dismount()
  }

  @Test func aNewFriendEarnedOnTheSameReadFollowsLevelOne() async {
    let store = TestStore(
      initialState: Self.levelOneFinished(then: [.newFriend(.hare, via: .trail)])
    ) { Reading() }

    store.send(.backToMyStoriesTapped) {
      $0.journeyMoments = [.newFriend(.hare, via: .trail)]
    }
    await store.dismount()
  }
}
