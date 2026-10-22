import ComposableArchitecture2
import Content
import Testing

@testable import AppFeature
@testable import GrownUps
@testable import Home

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct LockedStoryTests {
  private static let plusStory = StoryLibrary.stories(at: 2)[0]

  private static func locking(isPlus: Bool = false) -> Root.State {
    var state = Root.State()
    state.intro = nil
    state.home.locksStories = true
    state.home.isPlus = isPlus
    return state
  }

  @Test func aLockedStoryOpensTheCardNeverTheReader() async {
    let store = TestStore(initialState: Self.locking()) {
      Root()
    }
    let story = Self.plusStory
    store.send(.home(.storyTapped(story))) {
      $0.home.locked = LockedStory.State.DebugSnapshot(
        standing: StoryStanding(story: story, progress: Content.Progress())
      )
    }
    #expect(store.state.path.isEmpty)
    #expect(store.state.storyOnScreen == nil)
    await store.dismount()
  }

  @Test func aBigStoryThatIsLockedOpensTheCard() async {
    var state = Self.locking()
    state.journeyMap = JourneyMap.State()
    let store = TestStore(initialState: state) {
      Root()
    }
    let story = Self.plusStory
    store.send(.journeyMap(.bigStoryTapped(story))) {
      $0.journeyMap = nil
      $0.home.locked = LockedStory.State.DebugSnapshot(
        standing: StoryStanding(story: story, progress: Content.Progress())
      )
    }
    #expect(store.state.path.isEmpty)
    await store.dismount()
  }

  @Test func levelOneStaysOpenWhileLocking() {
    let home = Self.locking().home
    #expect(!home.isLocked(StoryLibrary.stories(at: 1)[0]))
    #expect(home.isLocked(Self.plusStory))
  }

  @Test func keepReadingNeverOffersALockedStory() {
    var home = Self.locking().home
    home.apply(
      Content.Progress(
        completedSentences: [Self.plusStory.id: 3], journey: Journey(starting: .hare)
      )
    )
    #expect(home.keepGoing?.story.level == 1)
  }

  @Test func plusOpensEveryStory() {
    let home = Self.locking(isPlus: true).home
    #expect(StoryLibrary.all.allSatisfy { !home.isLocked($0) })
  }

  @Test func plusFromTheStoreOpensTheLockedStories() async {
    var state = Home.State()
    state.hour = 9
    state.locksStories = true
    let store = TestStore(initialState: state) {
      Home()
        .dependency(PurchasesClient.fixed(true))
    }
    for _ in 0..<100 where !store.state.isPlus { await Task.yield() }
    store.expect { $0.isPlus = true }
    #expect(StoryLibrary.all.allSatisfy { !store.state.isLocked($0) })
    await store.dismount()
  }

  @Test func theReleaseSwitchLocksNothing() {
    let home = Root.State().home
    #expect(!home.locksStories)
    #expect(StoryLibrary.all.allSatisfy { !home.isLocked($0) })
  }

  @Test func theCardShowsTheStandingAndNothingWhenUnread() {
    let story = Self.plusStory
    let started = LockedStory.State(
      standing: StoryStanding(
        story: story, progress: Content.Progress(completedSentences: [story.id: 4])
      )
    )
    #expect(started.standingLine == "You read 4 of 6")
    let finished = LockedStory.State(
      standing: StoryStanding(
        story: story, progress: Content.Progress(completedSentences: [story.id: 6])
      )
    )
    #expect(finished.standingLine == "You read all 6")
    let unread = LockedStory.State(
      standing: StoryStanding(story: story, progress: Content.Progress())
    )
    #expect(unread.standingLine == nil)
  }

  @Test func askingAGrownUpGoesThroughTheGateAndBackHome() async {
    var state = Home.State()
    state.hour = 9
    state.locksStories = true
    state.showLocked(Self.plusStory)
    let store = TestStore(initialState: state) {
      Home()
    }
    store.send(.locked(.askAGrownUpTapped)) {
      $0.locked?.gate = ParentGate.State.DebugSnapshot(seed: 1)
    }
    store.send(.locked(.gate(.digitTapped(1)))) { $0.locked?.gate?.entry = "1" }
    store.send(.locked(.gate(.digitTapped(5)))) { $0.locked?.gate?.entry = "15" }
    store.send(.locked(.gate(.answerTapped)))
    await store.receive(\.locked.gate.passed) {
      $0.locked?.gate = nil
      $0.locked?.isPlusComing = true
    }
    store.send(.locked(.closeTapped)) { $0.locked = nil }
    await store.dismount()
  }

  @Test func closingTheGateGoesBackToTheCard() async {
    var state = Home.State()
    state.hour = 9
    state.showLocked(Self.plusStory)
    let store = TestStore(initialState: state) {
      Home()
    }
    store.send(.locked(.askAGrownUpTapped)) {
      $0.locked?.gate = ParentGate.State.DebugSnapshot(seed: 1)
    }
    store.send(.locked(.gate(.closeTapped))) { $0.locked?.gate = nil }
    store.send(.locked(.closeTapped)) { $0.locked = nil }
    await store.dismount()
  }
}
