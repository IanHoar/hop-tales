import ComposableArchitecture2
import DesignSystem
import SwiftUI

#if DEBUG
struct DebugControls: View {
  let store: StoreOf<Reading>

  var body: some View {
    HStack(spacing: 8) {
      button("Hear \(store.currentWord?.text ?? "—")") {
        guard let word = store.currentWord?.text else { return }
        store.send(.speechResult(tokens: [word], isFinal: true))
      }
      button("Sentence") {
        guard let words = store.sentence?.words else { return }
        for word in words[store.wordIndex...] {
          store.send(.speechResult(tokens: [word.text], isFinal: true))
        }
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(Palette.ink.opacity(0.75), in: .rect(cornerRadius: 14, style: .continuous))
    .accessibilityHidden(true)
  }

  private func button(_ title: String, action: @escaping () -> Void) -> some View {
    Button(title, action: action)
      .font(Typography.ui(13))
      .foregroundStyle(Palette.cream)
      .padding(.horizontal, 10)
      .frame(height: 32)
      .background(Palette.amberDeep.opacity(0.9), in: .capsule)
  }
}
#endif
