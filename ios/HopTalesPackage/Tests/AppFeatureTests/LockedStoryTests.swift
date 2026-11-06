import ComposableArchitecture
import Content
import DependenciesTestSupport
import Testing

@testable import AppFeature
@testable import GrownUps
@testable import Home

@MainActor
@Suite(.steady, .dependency(\.continuousClock, .immediate), .timeLimit(.minutes(1)))
struct LockedStoryTests {
  private static let plusStory = StoryLibrary.stories(at: 2)[0]
  private static let plusStoryWelcome = PlusWelcome(
    story: plusStory, friend: plusStory.friend, meetsFriend: false
  )
  private static let firstRunWelcome = PlusWelcome(
    story: StoryLibrary[Friend.bunny.startingStoryID]!, friend: .hare, meetsFriend: false
  )

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
    #expect(store.state.storyOnScreen == nil)
    await store.dismount()
  }

  @Test func aBigStoryThatIsLockedOpensTheCard() async {
    var progress = Content.Progress(journey: Journey(starting: .hare))
    progress.journey.steps = progress.journey.goal
    progress.journey.storiesRead = Set(StoryLibrary.stories(at: 2).map(\.id))
    let saved = progress
    var state = Self.locking()
    state.journeyMap = JourneyMap.State()
    state.journeyMap?.journey = saved.journey
    let store = TestStore(initialState: state) {
      Root()
        .dependency(ProgressStore(load: { saved }, save: { _ in }))
    }
    let story = StoryLibrary.bigStory(at: Friend.frog.level)!
    await store.send(.journeyMap(.stopTapped(.frog))) {
      $0.journeyMap = nil
      $0.home.locked = LockedStory.State.DebugSnapshot(
        standing: StoryStanding(story: story, progress: saved)
      )
    }?.value
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
    await store.receive(\.plusChanged) { $0.isPlus = true }
    #expect(StoryLibrary.all.allSatisfy { !store.state.isLocked($0) })
    await store.dismount()
  }

  @Test func theReleaseSwitchLocksEverythingAboveLevelOne() {
    let home = Root.State().home
    #expect(home.locksStories)
    #expect(StoryLibrary.all.allSatisfy { home.isLocked($0) == ($0.level != 1) })
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
        gate: ParentGate.State.DebugSnapshot(seed: 1), welcome: Self.plusStoryWelcome
      )
    }
    store.send(.locked(.grownUp(.gate(.digitTapped(1))))) { $0.locked?.grownUp?.gate?.entry = "1" }
    store.send(.locked(.grownUp(.gate(.digitTapped(5))))) { $0.locked?.grownUp?.gate?.entry = "15" }
    store.send(.locked(.grownUp(.gate(.answerTapped))))
    await store.receive(\.locked.grownUp.gate.passed) {
      $0.locked?.grownUp?.paywall = Paywall.State.DebugSnapshot(welcome: Self.plusStoryWelcome)
    }
    await store.receive(\.locked.grownUp.paywall.offersLoaded) {
      $0.locked?.grownUp?.paywall?.offers = .loaded(PlusOffer.samples)
    }
    store.send(.locked(.grownUp(.paywall(.closeTapped)))) { $0.locked?.grownUp = nil }
    store.send(.locked(.closeTapped)) { $0.locked = nil }
    await store.dismount()
  }

  @Test func subscribingWelcomesThenOpensTheLockedStory() async {
    var state = Home.State()
    state.hour = 9
    state.locksStories = false
    state.showLocked(Self.plusStory)
    state.locked?.grownUp = GrownUpPaywall.State(seed: 1, welcome: Self.plusStoryWelcome)
    state.locked?.grownUp?.gate = nil
    state.locked?.grownUp?.paywall = Paywall.State(welcome: Self.plusStoryWelcome)
    let store = TestStore(initialState: state) {
      Home()
        .dependency(PurchasesClient.fake())
    }
    await store.receive(\.locked.grownUp.paywall.offersLoaded) {
      $0.locked?.grownUp?.paywall?.offers = .loaded(PlusOffer.samples)
    }
    store.send(.locked(.grownUp(.paywall(.subscribeTapped)))) {
      $0.locked?.grownUp?.paywall?.work = .subscribing
    }
    await store.receive(\.locked.grownUp.paywall.purchaseCompleted) {
      $0.isPlus = true
      $0.locked?.grownUp?.paywall?.work = nil
      $0.locked?.grownUp?.paywall?.isSubscribed = true
    }
    store.send(.locked(.grownUp(.paywall(.readTapped)))) { $0.locked = nil }
    await store.receive(\.storyTapped)
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
        gate: ParentGate.State.DebugSnapshot(seed: 1), welcome: Self.plusStoryWelcome
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
    store.send(.levelTapped(.hare)) {
      $0.grownUp = GrownUpPaywall.State.DebugSnapshot(
        gate: ParentGate.State.DebugSnapshot(seed: 1), welcome: Self.firstRunWelcome
      )
    }
    store.send(.grownUp(.gate(.digitTapped(1)))) { $0.grownUp?.gate?.entry = "1" }
    store.send(.grownUp(.gate(.digitTapped(5)))) { $0.grownUp?.gate?.entry = "15" }
    store.send(.grownUp(.gate(.answerTapped)))
    await store.receive(\.grownUp.gate.passed) {
      $0.grownUp?.paywall = Paywall.State.DebugSnapshot(welcome: Self.firstRunWelcome)
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
    store.send(.levelTapped(.frog)) {
      $0.grownUp = GrownUpPaywall.State.DebugSnapshot(
        gate: ParentGate.State.DebugSnapshot(seed: 1), welcome: Self.firstRunWelcome
      )
    }
    store.send(.grownUp(.gate(.closeTapped))) { $0.grownUp = nil }
    await store.dismount()
  }
}

extension LockedStoryTests {
  @Test func subscribingFromALockedLevelWelcomesThenOpensTheNextStory() async {
    var state = Home.State()
    state.hour = 9
    state.grownUp = GrownUpPaywall.State(seed: 1, welcome: Self.firstRunWelcome)
    state.grownUp?.gate = nil
    state.grownUp?.paywall = Paywall.State(welcome: Self.firstRunWelcome)
    let store = TestStore(initialState: state) {
      Home()
        .dependency(PurchasesClient.fake())
    }
    await store.receive(\.grownUp.paywall.offersLoaded) {
      $0.grownUp?.paywall?.offers = .loaded(PlusOffer.samples)
    }
    store.send(.grownUp(.paywall(.subscribeTapped))) {
      $0.grownUp?.paywall?.work = .subscribing
    }
    await store.receive(\.grownUp.paywall.purchaseCompleted) {
      $0.isPlus = true
      $0.grownUp?.paywall?.work = nil
      $0.grownUp?.paywall?.isSubscribed = true
    }
    store.send(.grownUp(.paywall(.readTapped))) { $0.grownUp = nil }
    await store.receive(\.storyTapped)
    await store.dismount()
  }

  @Test func plusArrivingLaterClosesTheOpenPaywall() async {
    let (plus, arrives) = AsyncStream.makeStream(of: Bool.self)
    var state = Home.State()
    state.hour = 9
    state.grownUp = GrownUpPaywall.State(seed: 1)
    let store = TestStore(initialState: state) {
      Home()
        .dependency(PurchasesClient.streaming(plus))
    }
    arrives.yield(true)
    await store.receive(\.plusChanged) {
      $0.grownUp = nil
      $0.isPlus = true
    }
    arrives.finish()
    await store.dismount()
  }

  @Test func plusReadersStillSeeTheLevelsAhead() {
    let home = Self.locking(isPlus: true).home
    #expect(home.nextLevels == [.hare, .frog])
    #expect(home.standing(of: .hare) == .ahead)
  }

  @Test func readingEveryStoryOpensTheNextFriendsBigStoryForPlus() {
    var home = Self.locking(isPlus: true).home
    let stories = StoryLibrary.stories(at: 1)
    var progress = Content.Progress(
      completedSentences: Dictionary(uniqueKeysWithValues: stories.map { ($0.id, 99) })
    )
    progress.journey.storiesRead = Set(stories.map(\.id))
    home.apply(progress)
    let big = StoryLibrary.bigStory(at: 2)!
    #expect(home.standing(of: .hare) == .ready(big))
    #expect(home.keepGoing?.story == big)
    #expect(home.plusWelcome == PlusWelcome(story: big, friend: .hare, meetsFriend: true))
  }

  @Test func aFreeReaderWithTheBigStoryWaitingStillSeesItLocked() {
    var home = Self.locking().home
    var progress = Content.Progress()
    progress.journey.storiesRead = Set(StoryLibrary.stories(at: 1).map(\.id))
    home.apply(progress)
    #expect(home.standing(of: .hare) == .locked)
    #expect(home.keepGoing?.story.isBigStory != true)
  }
}
