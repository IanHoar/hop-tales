import ComposableArchitecture2
import Content
import Testing

@testable import Reading

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct EndOfStoryTests {
  private static func finished(with moments: [JourneyMoment]) -> Reading.State {
    var state = Reading.State(story: StoryLibrary.all[0])
    state.isActive = false
    state.sentenceIndex = state.story.sentences.count
    state.completed = .story(stars: 30)
    state.journeyMoments = moments
    return state
  }

  @Test func theBigStoryCardGoesBackToTheStoriesNotIntoTheBigStory() async {
    let store = TestStore(initialState: Self.finished(with: [.bigStoryReady(.bunny)])) {
      Reading()
    }

    store.send(.backToMyStoriesTapped) {
      $0.journeyMoments = []
    }
    await store.receive(\.backToStoriesTapped)
    await store.dismount()
  }

  @Test func aNewFriendGoesBackToTheStoriesNotIntoTheirFirstStory() async {
    let store = TestStore(
      initialState: Self.finished(with: [.newFriend(.hare, via: .trail)])
    ) { Reading() }

    store.send(.backToMyStoriesTapped) {
      $0.journeyMoments = []
    }
    await store.receive(\.backToStoriesTapped)
    await store.dismount()
  }

  @Test func theMomentsStillShowInOrderBeforeGoingBack() async {
    let store = TestStore(
      initialState: Self.finished(with: [
        .newFriend(.hare, via: .trail), .basketFull(.hare, number: 1)
      ])
    ) { Reading() }

    store.send(.backToMyStoriesTapped) {
      $0.journeyMoments = [.basketFull(.hare, number: 1)]
    }
    #expect(store.state.callout == .basketFull(.hare, number: 1))
    await store.dismount()
  }
}
