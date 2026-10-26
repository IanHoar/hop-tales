import ComposableArchitecture
import Content
import DesignSystem
import SpeechRecognition
import SwiftUI

struct AccentChoices: View {
  let store: StoreOf<Settings>

  var body: some View {
    ForEach(Profile.Accent.allCases, id: \.self) { accent in
      PaperChoice(title: accent.name, isSelected: accent == store.profile.accent) {
        store.send(.accentPicked(accent))
      }
    }
  }
}

struct ThemeChoices: View {
  let store: StoreOf<Settings>

  var body: some View {
    ForEach(Profile.Theme.allCases, id: \.self) { theme in
      PaperChoice(title: theme.name, isSelected: theme == store.profile.theme) {
        store.send(.themePicked(theme))
      }
    }
  }
}

struct StrictnessChoices: View {
  let store: StoreOf<Settings>

  var body: some View {
    ForEach(WordMatcher.Strictness.allCases, id: \.self) { strictness in
      PaperChoice(
        title: strictness.title,
        detail: strictness.detail,
        isSelected: strictness == store.strictness
      ) {
        store.send(.strictnessPicked(strictness))
      }
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

struct VoiceRow: View {
  let store: StoreOf<Settings>

  var body: some View {
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
            .font(Typography.display(19))
            .foregroundStyle(Paper.ink)
          Spacer(minLength: 0)
          Image(systemName: "chevron.up.chevron.down")
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(Paper.muted)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .settingsField()
        .contentShape(.rect(cornerRadius: 18))
      }
      .accessibilityLabel("Help voice, \(store.voiceName)")
      Button { store.send(.hearVoiceTapped) } label: {
        Image(systemName: "speaker.wave.2.fill")
          .font(.system(size: 18, weight: .bold))
          .foregroundStyle(Paper.ink)
          .frame(width: 56, height: 56)
          .paperChip(Circle(), rim: 3)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Hear the help voice")
    }
  }
}
