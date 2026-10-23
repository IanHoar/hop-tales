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

  @Test func askingAGrownUpGoesThroughTheGateToThePaywall() async {
    var state = Home.State()
    state.hour = 9
    state.locksStories = true
    state.showLocked(Self.plusStory)
    let store = TestStore(initialState: state) {
      Home()
        .dependency(PurchasesClient.fake())
    }
    store.send(.locked(.askAGrownUpTapped)) {
      $0.locked?.grownUp = GrownUpPaywall.State.DebugSnapshot(
        isOnboarding: false, gate: ParentGate.State.DebugSnapshot(seed: 1)
      )
    }
    store.send(.locked(.grownUp(.gate(.digitTapped(1))))) { $0.locked?.grownUp?.gate?.entry = "1" }
    store.send(.locked(.grownUp(.gate(.digitTapped(5))))) { $0.locked?.grownUp?.gate?.entry = "15" }
    store.send(.locked(.grownUp(.gate(.answerTapped))))
    await store.receive(\.locked.grownUp.gate.passed) {
      $0.locked?.grownUp?.gate = nil
      $0.locked?.grownUp?.paywall = Paywall.State.DebugSnapshot(isOnboarding: false)
    }
    await store.receive(\.locked.grownUp.paywall.offersLoaded) {
      $0.locked?.grownUp?.paywall?.offers = .loaded(PlusOffer.samples)
    }
    store.send(.locked(.grownUp(.paywall(.closeTapped)))) { $0.locked?.grownUp = nil }
    store.send(.locked(.closeTapped)) { $0.locked = nil }
    await store.dismount()
  }

  @Test func subscribingClosesTheCard() async {
    var state = Home.State()
    state.hour = 9
    state.showLocked(Self.plusStory)
    state.locked?.grownUp = GrownUpPaywall.State(seed: 1)
    state.locked?.grownUp?.gate = nil
    state.locked?.grownUp?.paywall = Paywall.State()
    let store = TestStore(initialState: state) {
      Home()
        .dependency(PurchasesClient.fake())
    }
    await store.receive(\.locked.grownUp.paywall.offersLoaded) {
      $0.locked?.grownUp?.paywall?.offers = .loaded(PlusOffer.samples)
    }
    store.send(.locked(.grownUp(.paywall(.planTapped(.yearly)))))
    await store.receive(\.locked.grownUp.paywall.purchaseCompleted)
    await store.receive(\.locked.grownUp.paywall.subscribed) { $0.locked = nil }
    await store.dismount()
  }

  @Test func tryLevelOneFreeClosesTheOnboardingPaywall() async {
    var state = Home.State()
    state.hour = 9
    state.showLocked(Self.plusStory)
    state.locked?.grownUp = GrownUpPaywall.State(seed: 1, isOnboarding: true)
    state.locked?.grownUp?.gate = nil
    state.locked?.grownUp?.paywall = Paywall.State(isOnboarding: true)
    let store = TestStore(initialState: state) {
      Home()
        .dependency(PurchasesClient.fake())
    }
    await store.receive(\.locked.grownUp.paywall.offersLoaded) {
      $0.locked?.grownUp?.paywall?.offers = .loaded(PlusOffer.samples)
    }
    store.send(.locked(.grownUp(.paywall(.tryLevelOneTapped)))) { $0.locked?.grownUp = nil }
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
      $0.locked?.grownUp = GrownUpPaywall.State.DebugSnapshot(
        isOnboarding: false, gate: ParentGate.State.DebugSnapshot(seed: 1)
      )
    }
    store.send(.locked(.grownUp(.gate(.closeTapped)))) { $0.locked?.grownUp = nil }
    store.send(.locked(.closeTapped)) { $0.locked = nil }
    await store.dismount()
  }

  @Test func aFreeReaderSeesTheNextTwoLevelsLocked() {
    #expect(Self.locking().home.lockedLevels == [.hare, .frog])
  }

  @Test func aReaderWithSkipSeesTheLevelsAfterHisLockedStories() {
    var home = Self.locking().home
    home.apply(Content.Progress(journey: Journey(starting: .hare)))
    #expect(home.lockedLevels == [.frog, .crow])
  }

  @Test func plusReadersSeeNoLockedLevels() {
    #expect(Self.locking(isPlus: true).home.lockedLevels.isEmpty)
  }

  @Test func noLockedLevelsWhileStoriesStayOpen() {
    var home = Self.locking().home
    home.locksStories = false
    #expect(home.lockedLevels.isEmpty)
  }

  @Test func aLockedLevelOpensTheGateThenThePaywall() async {
    var state = Home.State()
    state.hour = 9
    state.locksStories = true
    let store = TestStore(initialState: state) {
      Home()
        .dependency(PurchasesClient.fake())
    }
    store.send(.lockedLevelTapped(.hare)) {
      $0.grownUp = GrownUpPaywall.State.DebugSnapshot(
        isOnboarding: false, gate: ParentGate.State.DebugSnapshot(seed: 1)
      )
    }
    store.send(.grownUp(.gate(.digitTapped(1)))) { $0.grownUp?.gate?.entry = "1" }
    store.send(.grownUp(.gate(.digitTapped(5)))) { $0.grownUp?.gate?.entry = "15" }
    store.send(.grownUp(.gate(.answerTapped)))
    await store.receive(\.grownUp.gate.passed) {
      $0.grownUp?.gate = nil
      $0.grownUp?.paywall = Paywall.State.DebugSnapshot(isOnboarding: false)
    }
    await store.receive(\.grownUp.paywall.offersLoaded) {
      $0.grownUp?.paywall?.offers = .loaded(PlusOffer.samples)
    }
    store.send(.grownUp(.paywall(.closeTapped))) { $0.grownUp = nil }
    await store.dismount()
  }

  @Test func closingTheGateFromALockedLevelGoesBackHome() async {
    var state = Home.State()
    state.hour = 9
    state.locksStories = true
    let store = TestStore(initialState: state) {
      Home()
        .dependency(PurchasesClient.fake())
    }
    store.send(.lockedLevelTapped(.frog)) {
      $0.grownUp = GrownUpPaywall.State.DebugSnapshot(
        isOnboarding: false, gate: ParentGate.State.DebugSnapshot(seed: 1)
      )
    }
    store.send(.grownUp(.gate(.closeTapped))) { $0.grownUp = nil }
    await store.dismount()
  }

  @Test func subscribingFromALockedLevelClosesThePaywall() async {
    var state = Home.State()
    state.hour = 9
    state.grownUp = GrownUpPaywall.State(seed: 1)
    state.grownUp?.gate = nil
    state.grownUp?.paywall = Paywall.State()
    let store = TestStore(initialState: state) {
      Home()
        .dependency(PurchasesClient.fake())
    }
    await store.receive(\.grownUp.paywall.offersLoaded) {
      $0.grownUp?.paywall?.offers = .loaded(PlusOffer.samples)
    }
    store.send(.grownUp(.paywall(.planTapped(.yearly))))
    await store.receive(\.grownUp.paywall.purchaseCompleted)
    await store.receive(\.grownUp.paywall.subscribed) { $0.grownUp = nil }
    await store.dismount()
  }
}
