import ComposableArchitecture2
import Content
import Testing

@testable import GrownUps
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

  @Test func keepReadingAfterLevelOneGoesBackToTheStories() async {
    let store = TestStore(initialState: Self.levelOneFinished()) { Reading() }

    store.send(.levelOneKeepReadingTapped) {
      $0.journeyMoments = []
    }
    await store.receive(\.backToStoriesTapped)
    await store.dismount()
  }

  @Test func aNewFriendEarnedOnTheSameReadFollowsLevelOne() async {
    let store = TestStore(
      initialState: Self.levelOneFinished(then: [.newFriend(.hare, via: .trail)])
    ) { Reading() }

    store.send(.levelOneKeepReadingTapped) {
      $0.journeyMoments = [.newFriend(.hare, via: .trail)]
    }
    await store.dismount()
  }

  @Test func askAGrownUpOpensTheGateFirst() async {
    let store = TestStore(initialState: Self.levelOneFinished()) { Reading() }

    store.send(.askAGrownUpTapped) {
      $0.grownUp = GrownUpPaywall.State.DebugSnapshot(
        isOnboarding: false, gate: ParentGate.State.DebugSnapshot(seed: 1)
      )
    }
    store.send(.grownUp(.gate(.closeTapped))) {
      $0.grownUp = nil
    }
    #expect(store.state.callout == .levelOneFinished)
    await store.dismount()
  }

  @Test func subscribingClosesTheLevelOneCard() async {
    var state = Self.levelOneFinished()
    state.grownUp = GrownUpPaywall.State(seed: 1)
    state.grownUp?.gate = nil
    state.grownUp?.paywall = Paywall.State()
    let store = TestStore(initialState: state) {
      Reading()
        .dependency(PurchasesClient.fake())
    }

    await store.receive(\.grownUp.paywall.offersLoaded) {
      $0.grownUp?.paywall?.offers = .loaded(PlusOffer.samples)
    }
    store.send(.grownUp(.paywall(.planTapped(.yearly))))
    await store.receive(\.grownUp.paywall.purchaseCompleted)
    await store.receive(\.grownUp.paywall.subscribed) {
      $0.grownUp = nil
      $0.journeyMoments = []
    }
    await store.dismount()
  }
}
