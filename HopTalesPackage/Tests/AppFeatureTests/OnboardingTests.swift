import ComposableArchitecture2
import Content
import Dependencies
import SpeechRecognition
import Testing

@testable import AppFeature
@testable import Home
@testable import Onboarding

@MainActor
struct OnboardingTests {
  nonisolated static let voices = [
    SpeechClient.Voice(id: "ava", name: "Ava"),
    SpeechClient.Voice(id: "sam", name: "Samantha")
  ]

  nonisolated static let speech = SpeechClient(
    listen: { _, _ in AsyncStream { $0.finish() } },
    requestAuthorization: { _ in .authorized },
    speak: { _, _ in },
    voices: { _ in voices }
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

    await store.send(.continueTapped) { $0.path = [.name] }
    await store.send(.nameChanged("Maya")) { $0.childName = "Maya" }
    await store.send(.continueTapped) { $0.path = [.name, .listening] }
    await store.send(.continueTapped)
    await store.send(.listenTapped)
    await store.receive(\.authorizationResolved) { $0.authorization = .authorized }
    await store.send(.continueTapped) { $0.path = [.name, .listening, .story] }
    await store.send(.storyPicked(StoryLibrary.all[2].id)) {
      $0.startingStoryID = StoryLibrary.all[2].id
    }
    await store.send(.continueTapped) { $0.path = [.name, .listening, .story, .voice] }
    await store.receive(\.voicesLoaded) {
      $0.voices = Self.voices
      $0.voiceID = "ava"
    }
    await store.send(.accentPicked(.british)) { $0.accent = .british }
    await store.receive(\.voicesLoaded)
    await store.send(.voicePicked("sam")) { $0.voiceID = "sam" }
    await store.send(.continueTapped)
    await store.receive(\.finished)
  }

  @Test func listeningCanBeRefusedWithoutBlockingSetUp() async {
    var speech = Self.speech
    speech.requestAuthorization = { _ in .denied }
    let store = TestStore(initialState: Onboarding.State()) {
      Onboarding().dependency(speech)
    }
    await store.send(.continueTapped) { $0.path = [.name] }
    await store.send(.continueTapped) { $0.path = [.name, .listening] }
    await store.send(.listenTapped)
    await store.receive(\.authorizationResolved) { $0.authorization = .denied }
    await store.send(.continueTapped) { $0.path = [.name, .listening, .story] }
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

  @Test func swipingBackPopsAStepButCannotSkipAhead() async {
    var state = Onboarding.State()
    state.path = [.name, .listening]
    let store = TestStore(initialState: state) {
      Onboarding().dependency(Self.speech)
    }
    await store.send(.pathChanged([.name])) { $0.path = [.name] }
    await store.send(.pathChanged([.name, .listening, .story]))
  }
}
