import ComposableArchitecture2
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
