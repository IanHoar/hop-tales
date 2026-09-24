import ComposableArchitecture2
import Content
import Dependencies
import SpeechRecognition
import Testing

@testable import AppFeature
@testable import GrownUps
@testable import Home
@testable import Onboarding

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct OnboardingTests {
  nonisolated static let speech = SpeechClient(
    listen: { _, _ in AsyncStream { $0.finish() } },
    requestAuthorization: { _ in .authorized },
    speak: { _, _ in }
  )

  @Test func aFirstRunOpensOnboarding() throws {
    let store = try TestStore(initialState: Root.State()) {
      Root().dependency(ProfileStore.firstRun)
    } changes: {
      $0.onboarding = Onboarding.State.DebugSnapshot()
    }
    #expect(store.state.onboarding != nil)
  }

  @Test func aSavedProfileSkipsOnboardingAndGreetsTheChild() throws {
    let profile = Profile(childName: "Maya", startingStoryID: StoryLibrary.all[1].id)
    let store = try TestStore(initialState: Root.State()) {
      Root().dependency(ProfileStore(load: { profile }, save: { _ in }))
    } changes: {
      $0.home.childName = "Maya"
      $0.home.startingStoryID = StoryLibrary.all[1].id
    }
    #expect(store.state.onboarding == nil)
  }

  @Test func theGrownUpWalksThroughEveryStep() async {
    let store = TestStore(initialState: Onboarding.State()) {
      Onboarding().dependency(Self.speech)
    }

    await store.send(.primaryTapped)
    await store.send(.nameChanged("Maya")) { $0.childName = "Maya" }
    await store.send(.primaryTapped) { $0.path = [.listening] }
    #expect(store.state.primaryTitle == "Allow microphone")
    await store.send(.primaryTapped)
    await store.receive(\.authorizationResolved) { $0.authorization = .authorized }
    #expect(store.state.primaryTitle == "Continue")
    await store.send(.primaryTapped) { $0.path = [.listening, .story] }
    await store.send(.primaryTapped)
    await store.send(.storyPicked(StoryLibrary.all[2].id)) {
      $0.startingStoryID = StoryLibrary.all[2].id
    }
    await store.send(.primaryTapped) { $0.path = [.listening, .story, .accent] }
    await store.send(.primaryTapped)
    await store.send(.accentPicked(.british)) { $0.accent = .british }
    #expect(store.state.primaryTitle == "Start reading")
    await store.send(.primaryTapped)
    await store.receive(\.finished)
  }

  @Test func eachStepWaitsForAnAnswer() {
    var state = Onboarding.State()
    #expect(!state.canContinue(from: .name))
    state.childName = "   "
    #expect(!state.canContinue(from: .name))
    state.childName = "Maya"
    #expect(state.canContinue(from: .name))
    #expect(!state.canContinue(from: .listening))
    #expect(!state.canContinue(from: .story))
    #expect(!state.canContinue(from: .accent))
  }

  @Test func listeningCanBeRefusedWithoutBlockingSetUp() async {
    var speech = Self.speech
    speech.requestAuthorization = { _ in .denied }
    let store = TestStore(initialState: Onboarding.State()) {
      Onboarding().dependency(speech)
    }
    await store.send(.nameChanged("Maya")) { $0.childName = "Maya" }
    await store.send(.primaryTapped) { $0.path = [.listening] }
    await store.send(.primaryTapped)
    await store.receive(\.authorizationResolved) { $0.authorization = .denied }
    await store.send(.primaryTapped) { $0.path = [.listening, .story] }
  }

  @Test func finishingSavesTheProfileAndShowsTheStories() async throws {
    let saved = LockIsolated<Profile?>(nil)
    let store = try TestStore(initialState: Root.State()) {
      Root().dependency(ProfileStore(load: { nil }, save: { profile in saved.setValue(profile) }))
    } changes: {
      $0.onboarding = Onboarding.State.DebugSnapshot()
    }
    let profile = Profile(childName: "Maya", startingStoryID: StoryLibrary.all[1].id)
    await store.send(.onboarding(.finished(profile))) {
      $0.onboarding = nil
      $0.home.childName = "Maya"
      $0.home.startingStoryID = StoryLibrary.all[1].id
    }
    #expect(saved.value == profile)
  }

  @Test func theStartingStoryIsOfferedFirstUntilOneIsUnderway() {
    var home = Home.State()
    home.startingStoryID = StoryLibrary.all[1].id
    #expect(home.keepGoing?.story.id == StoryLibrary.all[1].id)
  }

  @Test func backReturnsToThePreviousQuestion() async {
    var state = Onboarding.State()
    state.path = [.listening, .story]
    let store = TestStore(initialState: state) {
      Onboarding().dependency(Self.speech)
    }
    await store.receive(\.authorizationResolved) { $0.authorization = .authorized }
    await store.send(.backTapped) { $0.path = [.listening] }
    await store.send(.backTapped) { $0.path = [] }
    await store.send(.backTapped)
  }

  @Test func everyAnswerIsKeptAsADraft() async {
    let draft = LockIsolated<ProfileDraft?>(nil)
    let store = TestStore(initialState: Onboarding.State()) {
      Onboarding()
        .dependency(Self.speech)
        .dependency(ProfileStore(load: { nil }, save: { _ in }, saveDraft: { draft.setValue($0) }))
    }
    await store.send(.nameChanged("Maya")) { $0.childName = "Maya" }
    #expect(draft.value == ProfileDraft(childName: "Maya", step: 1))
  }

  @Test func reopeningTheAppResumesAtTheLastStep() async throws {
    let draft = ProfileDraft(
      childName: "Maya",
      startingStoryID: StoryLibrary.all[2].id,
      step: Onboarding.Step.story.rawValue
    )
    let store = try TestStore(initialState: Root.State()) {
      Root()
        .dependency(ProfileStore(load: { nil }, save: { _ in }, loadDraft: { draft }))
        .dependency(Self.speech)
    } changes: {
      $0.onboarding = Onboarding.State.DebugSnapshot(
        path: [.listening, .story],
        childName: "Maya",
        startingStoryID: StoryLibrary.all[2].id
      )
    }
    await store.receive(\.onboarding.authorizationResolved) {
      $0.onboarding?.authorization = .authorized
    }
    await store.dismount()
  }

  @Test func aFullyAnsweredDraftOpensStraightToTheStories() throws {
    let draft = ProfileDraft(
      childName: "Maya",
      startingStoryID: StoryLibrary.all[1].id,
      accent: .american,
      step: Onboarding.Step.accent.rawValue
    )
    let saved = LockIsolated<Profile?>(nil)
    let store = try TestStore(initialState: Root.State()) {
      Root().dependency(
        ProfileStore(load: { nil }, save: { saved.setValue($0) }, loadDraft: { draft })
      )
    } changes: {
      $0.home.childName = "Maya"
      $0.home.startingStoryID = StoryLibrary.all[1].id
    }
    #expect(store.state.onboarding == nil)
    #expect(saved.value?.accent == .american)
  }

  @Test func resettingOnboardingForgetsTheProfile() async throws {
    let erased = LockIsolated(false)
    let profile = Profile(childName: "Maya")
    var state = Root.State()
    state.settings = Settings.State()
    let store = try TestStore(initialState: state) {
      Root().dependency(
        ProfileStore(load: { profile }, save: { _ in }, erase: { erased.setValue(true) })
      )
    } changes: {
      $0.home.childName = "Maya"
      $0.settings?.childName = "Maya"
      $0.settings?.profile = profile
    }
    await store.send(.settings(.resetOnboardingTapped)) {
      $0.home.childName = nil
      $0.onboarding = Onboarding.State.DebugSnapshot()
      $0.settings = nil
    }
    #expect(erased.value)
  }
}
