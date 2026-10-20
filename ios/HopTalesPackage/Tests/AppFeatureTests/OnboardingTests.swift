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

  @Test func aFirstRunOpensOnboarding() {
    let store = TestStore(initialState: Root.State()) {
      Root().dependency(ProfileStore.firstRun)
    } changes: {
      $0.onboarding = Onboarding.State.DebugSnapshot()
    }
    #expect(store.state.onboarding != nil)
  }

  @Test func aSavedProfileSkipsOnboardingAndGreetsTheChild() {
    let profile = Profile(childName: "Maya", startingFriend: .hare)
    let store = TestStore(initialState: Root.State()) {
      Root().dependency(ProfileStore(load: { profile }, save: { _ in }))
    } changes: {
      $0.home.childName = "Maya"
    }
    #expect(store.state.onboarding == nil)
  }

  @Test func theGrownUpWalksThroughEveryStep() async {
    let store = TestStore(initialState: Onboarding.State()) {
      Onboarding().dependency(Self.speech)
    }

    store.send(.primaryTapped)
    store.send(.cloudSyncPicked(false)) { $0.cloudSync = false }
    store.send(.primaryTapped) { $0.path = [.name] }
    store.send(.primaryTapped)
    store.send(.nameChanged("Maya")) { $0.childName = "Maya" }
    store.send(.primaryTapped) { $0.path = [.name, .listening] }
    #expect(store.state.primaryTitle == "Allow microphone")
    store.send(.primaryTapped)
    await store.receive(\.authorizationResolved) { $0.authorization = .authorized }
    #expect(store.state.primaryTitle == "Continue")
    store.send(.primaryTapped) { $0.path = [.name, .listening, .friend] }
    store.send(.primaryTapped)
    store.send(.friendPicked(.frog)) {
      $0.startingFriend = .frog
    }
    store.send(.primaryTapped) { $0.path = [.name, .listening, .friend, .soundButtons] }
    store.send(.primaryTapped)
    store.send(.soundButtonsPicked(true)) { $0.soundButtons = true }
    #expect(store.state.primaryTitle == "Start reading")
    store.send(.primaryTapped)
    await store.receive(\.finished)
  }

  private func cloud(
    restoring profile: Profile?,
    enabled: LockIsolated<Bool?>,
    canListen: Bool = false
  ) -> some FeatureProtocol<Onboarding.State, Onboarding.Action> {
    var speech = Self.speech
    speech.isAuthorized = { canListen }
    return Onboarding()
      .dependency(speech)
      .dependency(ProfileStore(load: { profile }, save: { _ in }))
      .dependency(
        CloudSync(
          account: { .available },
          isEnabled: { enabled.value ?? false },
          setEnabled: { enabled.setValue($0) }
        )
      )
  }

  @Test func savingToICloudOnANewDeviceBringsTheReaderBack() async {
    let enabled = LockIsolated<Bool?>(nil)
    let maya = Profile(childName: "Maya", startingFriend: .frog, voiceID: "v1")
    let store = TestStore(initialState: Onboarding.State()) {
      cloud(restoring: maya, enabled: enabled)
    }
    store.send(.cloudSyncPicked(true)) { $0.cloudSync = true }
    await store.receive(\.cloudAccountResolved) { $0.cloudAccount = .available }
    store.send(.primaryTapped) { $0.isCatchingUp = true }
    #expect(store.state.primaryTitle == "Checking iCloud…")
    await store.receive(\.cloudCaughtUp) {
      $0.isCatchingUp = false
      $0.restored = maya
      $0.path = [.listening]
    }
    #expect(enabled.value == true)
    #expect(store.state.stepNumber == 2)
    #expect(store.state.steps.count == 2)
    store.send(.primaryTapped)
    await store.receive(\.authorizationResolved) { $0.authorization = .authorized }
    #expect(store.state.primaryTitle == "Start reading")
    store.send(.primaryTapped)
    await store.receive(\.finished)
  }

  @Test func aRestoredReaderWhoCanAlreadyBeHeardGoesStraightToTheStories() async {
    let maya = Profile(childName: "Maya", startingFriend: .frog)
    let store = TestStore(initialState: Onboarding.State()) {
      cloud(restoring: maya, enabled: LockIsolated(nil), canListen: true)
    }
    store.send(.cloudSyncPicked(true)) { $0.cloudSync = true }
    await store.receive(\.cloudAccountResolved) { $0.cloudAccount = .available }
    store.send(.primaryTapped) { $0.isCatchingUp = true }
    await store.receive(\.finished)
  }

  @Test func savingToICloudWithNothingSavedCarriesOnWithSetUp() async {
    let store = TestStore(initialState: Onboarding.State()) {
      cloud(restoring: nil, enabled: LockIsolated(nil))
    }
    store.send(.cloudSyncPicked(true)) { $0.cloudSync = true }
    await store.receive(\.cloudAccountResolved) { $0.cloudAccount = .available }
    store.send(.primaryTapped) { $0.isCatchingUp = true }
    await store.receive(\.cloudCaughtUp) {
      $0.isCatchingUp = false
      $0.path = [.name]
    }
  }

  @Test func eachStepWaitsForAnAnswer() {
    var state = Onboarding.State()
    #expect(!state.canContinue(from: .name))
    state.childName = "   "
    #expect(!state.canContinue(from: .name))
    state.childName = "Maya"
    #expect(state.canContinue(from: .name))
    #expect(!state.canContinue(from: .listening))
    #expect(!state.canContinue(from: .friend))
    #expect(!state.canContinue(from: .soundButtons))
    #expect(!state.canContinue(from: .cloud))
  }

  @Test func listeningCanBeRefusedWithoutBlockingSetUp() async {
    var speech = Self.speech
    speech.requestAuthorization = { _ in .denied }
    var state = Onboarding.State()
    state.path = [.name]
    let store = TestStore(initialState: state) {
      Onboarding().dependency(speech)
    }
    store.send(.nameChanged("Maya")) { $0.childName = "Maya" }
    store.send(.primaryTapped) { $0.path = [.name, .listening] }
    store.send(.primaryTapped)
    await store.receive(\.authorizationResolved) { $0.authorization = .denied }
    store.send(.primaryTapped) { $0.path = [.name, .listening, .friend] }
  }

  @Test func finishingSavesTheProfileAndShowsTheStories() {
    let saved = LockIsolated<Profile?>(nil)
    let store = TestStore(initialState: Root.State()) {
      Root().dependency(ProfileStore(load: { nil }, save: { profile in saved.setValue(profile) }))
    } changes: {
      $0.onboarding = Onboarding.State.DebugSnapshot()
    }
    let profile = Profile(childName: "Maya", startingFriend: .hare)
    store.send(.onboarding(.finished(profile))) {
      $0.onboarding = nil
      $0.home.childName = "Maya"
    }
    #expect(saved.value == profile)
  }

  @Test func theStartingStoryIsOfferedFirstUntilOneIsUnderway() {
    var home = Home.State()
    home.apply(Content.Progress(journey: Journey(starting: .hare)))
    #expect(home.keepGoing?.story.id == StoryLibrary.all[1].id)
  }

  @Test func backReturnsToThePreviousQuestion() async {
    var state = Onboarding.State()
    state.path = [.name, .listening, .friend]
    let store = TestStore(initialState: state) {
      Onboarding().dependency(Self.speech)
    }
    await store.receive(\.authorizationResolved) { $0.authorization = .authorized }
    store.send(.backTapped) { $0.path = [.name, .listening] }
    store.send(.backTapped) { $0.path = [.name] }
    store.send(.backTapped) { $0.path = [] }
    store.send(.backTapped)
    await store.dismount()
  }

  @Test func everyAnswerIsKeptAsADraft() {
    let draft = LockIsolated<ProfileDraft?>(nil)
    let store = TestStore(initialState: Onboarding.State()) {
      Onboarding()
        .dependency(Self.speech)
        .dependency(ProfileStore(load: { nil }, save: { _ in }, saveDraft: { draft.setValue($0) }))
    }
    store.send(.nameChanged("Maya")) { $0.childName = "Maya" }
    #expect(draft.value == ProfileDraft(childName: "Maya", step: 1))
  }

  @Test func reopeningTheAppResumesAtTheLastStep() async {
    let draft = ProfileDraft(
      childName: "Maya",
      startingFriend: .frog,
      step: Onboarding.Step.friend.rawValue
    )
    let store = TestStore(initialState: Root.State()) {
      Root()
        .dependency(ProfileStore(load: { nil }, save: { _ in }, loadDraft: { draft }))
        .dependency(Self.speech)
    } changes: {
      $0.onboarding = Onboarding.State.DebugSnapshot(
        path: [.name, .listening, .friend],
        childName: "Maya",
        startingFriend: .frog
      )
    }
    await store.receive(\.onboarding.authorizationResolved) {
      $0.onboarding?.authorization = .authorized
    }
    await store.dismount()
  }

  @Test func aFullyAnsweredDraftOpensStraightToTheStories() {
    let draft = ProfileDraft(
      childName: "Maya",
      startingFriend: .hare,
      accent: .american,
      soundButtons: true,
      cloudSync: false,
      step: Onboarding.Step.soundButtons.rawValue
    )
    let saved = LockIsolated<Profile?>(nil)
    let store = TestStore(initialState: Root.State()) {
      Root().dependency(
        ProfileStore(load: { nil }, save: { saved.setValue($0) }, loadDraft: { draft })
      )
    } changes: {
      $0.home.childName = "Maya"
    }
    #expect(store.state.onboarding == nil)
    #expect(saved.value?.accent == .american)
    #expect(saved.value?.soundButtons == true)
  }

  @Test func resettingOnboardingForgetsTheProfile() {
    let erased = LockIsolated(false)
    let profile = Profile(childName: "Maya")
    var state = Root.State()
    state.settings = Settings.State()
    let store = TestStore(initialState: state) {
      Root().dependency(
        ProfileStore(load: { profile }, save: { _ in }, erase: { erased.setValue(true) })
      )
    } changes: {
      $0.home.childName = "Maya"
      $0.settings?.childName = "Maya"
      $0.settings?.profile = profile
    }
    store.send(.settings(.resetOnboardingTapped)) {
      $0.home.childName = nil
      $0.onboarding = Onboarding.State.DebugSnapshot()
      $0.settings = nil
    }
    #expect(erased.value)
  }
}
