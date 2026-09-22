import ComposableArchitecture2
import DesignSystem
import SpeechRecognition
import SwiftUI

#if DEBUG
extension Reading.Action {
  static func readCurrentWord(_ state: Reading.State) -> Reading.Action? {
    // The live client normalises before the feature ever sees a token, and accepts() compares a
    // raw token against a lowercased target — so "The" and "mat." both miss without this.
    guard let word = state.currentWord?.text else { return nil }
    return .speechResult(tokens: WordMatcher.normalize(word), isFinal: true)
  }
}

struct DebugControls: View {
  let store: StoreOf<Reading>

  var body: some View {
    HStack(spacing: 8) {
      button("Read “\(store.currentWord?.text ?? "—")”") {
        readCurrentWord()
      }
      button("Rest of sentence") {
        guard let words = store.sentence?.words else { return }
        for _ in words[store.wordIndex...] { readCurrentWord() }
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(Palette.ink.opacity(0.75), in: .rect(cornerRadius: 14, style: .continuous))
    .accessibilityHidden(true)
  }

  private func readCurrentWord() {
    guard let action = Reading.Action.readCurrentWord(store.state) else { return }
    store.send(action)
  }

  private func button(_ title: String, action: @escaping () -> Void) -> some View {
    Button(title, action: action)
      .font(Typography.ui(13))
      .foregroundStyle(Palette.cream)
      .padding(.horizontal, 12)
      .frame(height: 34)
      .background(Palette.amberDeep.opacity(0.9), in: .capsule)
  }
}

struct DebugTapToAdvance: ViewModifier {
  let store: StoreOf<Reading>

  func body(content: Content) -> some View {
    content
      .contentShape(.rect)
      .onTapGesture {
        guard let action = Reading.Action.readCurrentWord(store.state) else { return }
        store.send(action)
      }
  }
}
#endif
