import ComposableArchitecture2
import Content
import Dependencies
import DesignSystem
import SpeechRecognition
import SwiftUI

@Feature public struct Settings {
  public static let sample = "Let's read together!"

  public init() {}

  public struct State {
    public var profile = Profile()
    public var soundOn = true
    public var strictness: WordMatcher.Strictness = .gentle
    public var voices: [Voice] = []

    public init() {}

    public var voiceName: String {
      guard let id = profile.voiceID, let voice = voices.first(where: { $0.id == id }) else {
        return "Automatic"
      }
      return voice.name
    }
  }

  public enum Action {
    case accentPicked(Profile.Accent)
    case doneTapped
    case hearVoiceTapped
    case nameChanged(String)
    case soundToggled(Bool)
    case strictnessPicked(WordMatcher.Strictness)
    case voicePicked(String?)
  }

  @Dependency(ProfileStore.self) var profileStore
  @Dependency(SoundPreference.self) var soundPreference
  @Dependency(SpeechClient.self) var speechClient
  @Dependency(StrictnessPreference.self) var strictnessPreference

  private func save(_ profile: Profile) {
    var saved = profile
    saved.childName = profile.childName.trimmingCharacters(in: .whitespacesAndNewlines)
    profileStore.save(saved)
  }

  public var body: some Feature {
    Update { state, action in
      switch action {
      case let .accentPicked(accent):
        state.profile.accent = accent
        save(state.profile)

      case .doneTapped:
        break

      case .hearVoiceTapped:
        let voice = state.profile.voiceID
        store.addTask { await speechClient.speak(Settings.sample, voice) }

      case let .nameChanged(name):
        state.profile.childName = String(name.prefix(24))
        save(state.profile)

      case let .soundToggled(isOn):
        state.soundOn = isOn
        soundPreference.save(isOn)

      case let .strictnessPicked(strictness):
        state.strictness = strictness
        strictnessPreference.save(strictness)

      case let .voicePicked(id):
        state.profile.voiceID = id
        save(state.profile)
        store.addTask { await speechClient.speak(Settings.sample, id) }
      }
    }
    .onMount { state in
      state.profile = profileStore.load() ?? Profile()
      state.soundOn = soundPreference.load()
      state.strictness = strictnessPreference.load()
      state.voices = speechClient.voices()
    }
  }
}

extension WordMatcher.Strictness {
  var title: String {
    switch self {
    case .gentle: "Gentle"
    case .standard: "Standard"
    }
  }

  var detail: String {
    switch self {
    case .gentle:
      "Accepts close tries, dropped endings and sound-alikes. Best for new readers."
    case .standard:
      "Wants each word said clearly. A small slip is still fine."
    }
  }
}

public struct SettingsScreen: View {
  let store: StoreOf<Settings>

  public init(store: StoreOf<Settings>) {
    self.store = store
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 30) {
        Text("Grown-ups")
          .font(Typography.display(32))
          .foregroundStyle(Palette.ink)
          .accessibilityAddTraits(.isHeader)
        section("Reader") { name }
        section("Accent") {
          ForEach(Profile.Accent.allCases, id: \.self) { accent in
            Choice(title: accent.name, isSelected: accent == store.profile.accent) {
              store.send(.accentPicked(accent))
            }
          }
        }
        section("Listening") {
          ForEach(WordMatcher.Strictness.allCases, id: \.self) { strictness in
            Choice(
              title: strictness.title,
              detail: strictness.detail,
              isSelected: strictness == store.strictness
            ) {
              store.send(.strictnessPicked(strictness))
            }
          }
        }
        section("Help voice") { voice }
        section("Sounds") { sound }
      }
      .padding(.horizontal, 24)
      .padding(.top, 24)
      .padding(.bottom, 16)
      .frame(maxWidth: 560)
      .frame(maxWidth: .infinity)
    }
    .scrollBounceBehavior(.basedOnSize)
    .safeAreaInset(edge: .bottom) {
      Button { store.send(.doneTapped) } label: {
        Text("Done").frame(maxWidth: 560)
      }
      .buttonStyle(.ink(.primary))
      .padding(.horizontal, 24)
      .padding(.top, 12)
      .padding(.bottom, 16)
      .background(Palette.page)
    }
    .background(Palette.page.ignoresSafeArea())
  }

  private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title.uppercased())
        .font(Typography.display(15))
        .tracking(15 * 0.12)
        .foregroundStyle(Palette.ink)
        .padding(.horizontal, 4)
        .accessibilityAddTraits(.isHeader)
      content()
    }
  }

  private var field: some InsettableShape {
    RoundedRectangle(cornerRadius: 20, style: .continuous)
  }

  private var name: some View {
    TextField(
      "Name or nickname",
      text: Binding(get: { store.profile.childName }, set: { store.send(.nameChanged($0)) })
    )
    .font(Typography.ui(22))
    .foregroundStyle(Palette.ink)
    .textContentType(.nickname)
    .autocorrectionDisabled()
    .submitLabel(.done)
    .padding(.horizontal, 20)
    .frame(height: 60)
    .bevel(Palette.paper, lip: Palette.parchmentLip, shape: field, border: 3, drop: 4)
  }

  private var voice: some View {
    HStack(spacing: 12) {
      Menu {
        Picker(
          "Help voice",
          selection: Binding(get: { store.profile.voiceID }, set: { store.send(.voicePicked($0)) })
        ) {
          Text("Automatic").tag(String?.none)
          ForEach(store.voices) { voice in
            Text("\(voice.name) · \(voice.region)").tag(Optional(voice.id))
          }
        }
      } label: {
        HStack {
          Text(store.voiceName)
            .font(Typography.ui(20))
            .foregroundStyle(Palette.ink)
          Spacer(minLength: 0)
          Image(systemName: "chevron.up.chevron.down")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Palette.muted)
        }
        .padding(.horizontal, 20)
        .frame(height: 60)
        .bevel(Palette.paper, lip: Palette.parchmentLip, shape: field, border: 3, drop: 4)
        .contentShape(.rect(cornerRadius: 20))
      }
      .accessibilityLabel("Help voice, \(store.voiceName)")
      Button { store.send(.hearVoiceTapped) } label: {
        Image(systemName: "speaker.wave.2.fill")
          .font(.system(size: 20, weight: .bold))
      }
      .buttonStyle(.ink(.secondary))
      .accessibilityLabel("Hear the help voice")
    }
  }

  private var sound: some View {
    Toggle(
      isOn: Binding(get: { store.soundOn }, set: { store.send(.soundToggled($0)) })
    ) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Sound effects")
          .font(Typography.display(20))
          .foregroundStyle(Palette.ink)
        Text("The chime when a sentence is finished.")
          .font(Typography.ui(15))
          .foregroundStyle(Palette.muted)
      }
    }
    .tint(Palette.teal)
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
    .bevel(Palette.paper, lip: Palette.parchmentLip, shape: field, border: 3, drop: 4)
  }
}
