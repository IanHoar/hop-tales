import ComposableArchitecture2
import Content
import Dependencies
import Foundation
import SpeechRecognition
import Testing

@testable import AppFeature
@testable import GrownUps
@testable import Home

@MainActor
struct GrownUpsTests {
  static let question = GateQuestion(left: 7, right: 6)

  nonisolated static let voices = [
    Voice(id: "com.apple.voice.enhanced.en-US.Samantha", name: "Samantha", language: "en-US")
  ]

  @Test func theQuestionIsSpelledOutInWords() {
    #expect(Self.question.prompt == "What is seven times six?")
    #expect(Self.question.answer == 42)
    #expect(Self.question.digits == 2)
  }

  @Test func theLiveQuestionsNeedAnAdultsArithmetic() {
    for _ in 0..<50 {
      let question = GateQuestions.liveValue.next()
      #expect(GateQuestions.factors.contains(question.left))
      #expect(GateQuestions.factors.contains(question.right))
      #expect(question.answer >= 9)
    }
  }

  @Test func theGrownUpsButtonOpensTheGateAndCancelClosesIt() async {
    let store = TestStore(initialState: Root.State()) {
      Root()
    }

    await store.send(.home(.grownUpsTapped)) {
      $0.grownUps = GrownUps.State.DebugSnapshot(
        gate: ParentGate.State.DebugSnapshot(question: Self.question)
      )
    }
    await store.send(.grownUps(.gate(.cancelTapped))) {
      $0.grownUps = nil
    }
  }

  @Test func aWrongAnswerAsksAnotherQuestion() async {
    let store = TestStore(initialState: ParentGate.State(question: Self.question)) {
      ParentGate()
    }

    await store.send(.digitTapped(4)) { $0.entry = "4" }
    await store.send(.digitTapped(8)) {
      $0.entry = ""
      $0.missed = 1
    }
    await store.send(.digitTapped(4)) { $0.entry = "4" }
    await store.send(.deleteTapped) { $0.entry = "" }
  }

  @Test func theRightAnswerOpensTheSettings() async {
    let store = TestStore(initialState: GrownUps.State(question: Self.question)) {
      GrownUps()
        .dependency(ProfileStore(load: { Profile(childName: "Maya") }, save: { _ in }))
        .dependency(
          SpeechClient(
            listen: { _, _ in AsyncStream { $0.finish() } },
            requestAuthorization: { _ in .authorized },
            speak: { _, _ in },
            voices: { Self.voices }
          )
        )
    }

    await store.send(.gate(.digitTapped(4))) { $0.gate.entry = "4" }
    await store.send(.gate(.digitTapped(2))) { $0.gate.entry = "42" }
    await store.receive(\.gate.unlocked) {
      $0.settings = Settings.State.DebugSnapshot(
        childName: "Maya",
        profile: Profile(childName: "Maya"),
        voices: Self.voices
      )
    }
  }

  @Test func everySettingIsSavedAsItChanges() async {
    let profiles = LockIsolated<[Profile]>([])
    let strictness = LockIsolated<WordMatcher.Strictness?>(nil)
    let sound = LockIsolated<Bool?>(nil)
    let spoken = LockIsolated<[String?]>([])
    let voice = Self.voices[0].id
    let store = TestStore(initialState: Settings.State()) {
      Settings()
        .dependency(
          ProfileStore(
            load: { Profile(childName: "Maya") },
            save: { profile in profiles.withValue { $0.append(profile) } }
          )
        )
        .dependency(StrictnessPreference(load: { .gentle }, save: { strictness.setValue($0) }))
        .dependency(SoundPreference(load: { true }, save: { sound.setValue($0) }))
        .dependency(
          SpeechClient(
            listen: { _, _ in AsyncStream { $0.finish() } },
            requestAuthorization: { _ in .authorized },
            speak: { _, id in spoken.withValue { $0.append(id) } },
            voices: { Self.voices }
          )
        )
    } changes: {
      $0.childName = "Maya"
      $0.profile = Profile(childName: "Maya")
      $0.voices = Self.voices
    }

    await store.send(.nameChanged("Maya Rose ")) { $0.childName = "Maya Rose " }
    await store.send(.nameSubmitted)
    #expect(profiles.value.last?.childName == "Maya Rose")

    await store.send(.accentPicked(.british)) { $0.profile.accent = .british }
    #expect(profiles.value.last?.accent == .british)

    await store.send(.voicePicked(voice)) {
      $0.profile.voiceID = voice
    }?.value
    #expect(profiles.value.last?.voiceID == voice)

    await store.send(.strictnessPicked(.standard)) { $0.strictness = .standard }
    #expect(strictness.value == .standard)

    await store.send(.soundToggled(false)) { $0.soundOn = false }
    #expect(sound.value == false)

    await store.send(.hearVoiceTapped)?.value
    #expect(spoken.value == [voice, voice])
  }

  @Test func theNameIsSavedWhenTheGrownUpIsDone() async {
    let profiles = LockIsolated<[Profile]>([])
    let store = TestStore(initialState: Settings.State()) {
      Settings()
        .dependency(
          ProfileStore(
            load: { Profile(childName: "Maya") },
            save: { profile in profiles.withValue { $0.append(profile) } }
          )
        )
    } changes: {
      $0.childName = "Maya"
      $0.profile = Profile(childName: "Maya")
    }

    await store.send(.nameChanged("Wren")) { $0.childName = "Wren" }
    #expect(profiles.value.isEmpty)
    await store.send(.doneTapped)
    #expect(profiles.value.last?.childName == "Wren")
  }

  @Test func aLongNameIsCutShort() async {
    let store = TestStore(initialState: Settings.State()) {
      Settings()
    }

    await store.send(.nameChanged(String(repeating: "a", count: 30))) {
      $0.childName = String(repeating: "a", count: 24)
    }
  }

  @Test func doneClosesTheSettingsAndGreetsTheNewName() async {
    let saved = LockIsolated(Profile(childName: "Maya"))
    var state = Root.State()
    state.grownUps = GrownUps.State(question: Self.question)
    let store = TestStore(initialState: state) {
      Root()
        .dependency(
          ProfileStore(load: { saved.value }, save: { profile in saved.setValue(profile) })
        )
    } changes: {
      $0.home.childName = "Maya"
    }

    await store.send(.grownUps(.gate(.digitTapped(4)))) { $0.grownUps?.gate.entry = "4" }
    await store.send(.grownUps(.gate(.digitTapped(2)))) { $0.grownUps?.gate.entry = "42" }
    await store.receive(\.grownUps.gate.unlocked) {
      $0.grownUps?.settings = Settings.State.DebugSnapshot(
        childName: "Maya",
        profile: Profile(childName: "Maya")
      )
    }
    await store.send(.grownUps(.settings(.nameChanged("Wren")))) {
      $0.grownUps?.settings?.childName = "Wren"
    }
    await store.send(.grownUps(.settings(.doneTapped))) {
      $0.grownUps = nil
      $0.home.childName = "Wren"
    }
  }
}
