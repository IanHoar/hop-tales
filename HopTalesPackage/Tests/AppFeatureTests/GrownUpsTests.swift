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
@Suite(.timeLimit(.minutes(1)))
struct GrownUpsTests {
  nonisolated static let voices = [
    Voice(id: "com.apple.voice.enhanced.en-US.Samantha", name: "Samantha", language: "en-US")
  ]

  @Test func theGrownUpsButtonOpensTheSettings() {
    let store = TestStore(initialState: Root.State()) {
      Root()
        .dependency(ProfileStore(load: { Profile(childName: "Maya") }, save: { _ in }))
        .dependency(
          SpeechClient(
            listen: { _, _ in AsyncStream { $0.finish() } },
            requestAuthorization: { _ in .authorized },
            speak: { _, _ in },
            voices: { Self.voices }
          )
        )
    } changes: {
      $0.home.childName = "Maya"
    }

    store.send(.home(.grownUpsTapped)) {
      $0.settings = Settings.State.DebugSnapshot(
        childName: "Maya",
        profile: Profile(childName: "Maya"),
        voices: Self.voices
      )
    }
  }

  @Test func savingToICloudCanBeTurnedOnAndTheCopyDeleted() async {
    let enabled = LockIsolated<[Bool]>([])
    let deleted = LockIsolated(false)
    let store = TestStore(initialState: Settings.State()) {
      Settings()
        .dependency(ProfileStore(load: { nil }, save: { _ in }))
        .dependency(
          CloudSync(
            account: { .signedOut },
            isEnabled: { false },
            setEnabled: { isOn in enabled.withValue { $0.append(isOn) } },
            deleteCloudCopy: { deleted.setValue(true) }
          )
        )
    }
    store.send(.cloud(.toggled(true))) { $0.cloudSync = true }
    await store.receive(\.cloud.accountResolved) { $0.cloudAccount = .signedOut }
    store.send(.cloud(.deleteTapped)) { $0.isConfirmingCloudDelete = true }
    store.send(.cloud(.deleteConfirmed))
    await store.receive(\.cloud.copyDeleted) {
      $0.cloudNote = .deleted
      $0.cloudSync = false
    }
    #expect(enabled.value == [true])
    #expect(deleted.value)
    await store.dismount()
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

    store.send(.nameChanged("Maya Rose ")) { $0.childName = "Maya Rose " }
    store.send(.nameSubmitted)
    #expect(profiles.value.last?.childName == "Maya Rose")

    store.send(.accentPicked(.british)) { $0.profile.accent = .british }
    #expect(profiles.value.last?.accent == .british)

    store.send(.themePicked(.dark)) { $0.profile.theme = .dark }
    #expect(profiles.value.last?.theme == .dark)

    await store.send(.voicePicked(voice)) {
      $0.profile.voiceID = voice
    }?.value
    #expect(profiles.value.last?.voiceID == voice)

    store.send(.strictnessPicked(.standard)) { $0.strictness = .standard }
    #expect(strictness.value == .standard)

    store.send(.soundToggled(false)) { $0.soundOn = false }
    #expect(sound.value == false)

    await store.send(.hearVoiceTapped)?.value
    #expect(spoken.value == [voice, voice])
  }

  @Test func theNameIsSavedWhenTheGrownUpIsDone() {
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

    store.send(.nameChanged("Wren")) { $0.childName = "Wren" }
    #expect(profiles.value.isEmpty)
    store.send(.doneTapped)
    #expect(profiles.value.last?.childName == "Wren")
  }

  @Test func aLongNameIsCutShort() {
    let store = TestStore(initialState: Settings.State()) {
      Settings()
    }

    store.send(.nameChanged(String(repeating: "a", count: 30))) {
      $0.childName = String(repeating: "a", count: 24)
    }
  }

  @Test func doneClosesTheSettingsAndGreetsTheNewName() {
    let saved = LockIsolated(Profile(childName: "Maya"))
    var state = Root.State()
    state.settings = Settings.State()
    let store = TestStore(initialState: state) {
      Root()
        .dependency(
          ProfileStore(load: { saved.value }, save: { profile in saved.setValue(profile) })
        )
    } changes: {
      $0.home.childName = "Maya"
      $0.settings?.childName = "Maya"
      $0.settings?.profile = Profile(childName: "Maya")
    }

    store.send(.settings(.nameChanged("Wren"))) {
      $0.settings?.childName = "Wren"
    }
    store.send(.settings(.doneTapped)) {
      $0.settings = nil
      $0.home.childName = "Wren"
    }
  }

  @Test func pickingAThemeChangesTheWholeApp() {
    let saved = Profile(childName: "Maya", theme: .light)
    var root = Root.State()
    root.intro = nil
    root.theme = .light
    root.settings = Settings.State()
    let store = TestStore(initialState: root) {
      Root()
        .dependency(ProfileStore(load: { saved }, save: { _ in }))
    } changes: {
      $0.home.childName = "Maya"
      $0.settings?.childName = "Maya"
      $0.settings?.profile = saved
    }
    store.send(.settings(.themePicked(.dark))) {
      $0.theme = .dark
      $0.settings?.profile.theme = .dark
    }
  }
}
