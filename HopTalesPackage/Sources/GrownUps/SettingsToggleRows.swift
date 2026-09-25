import ComposableArchitecture2
import DesignSystem
import SwiftUI

struct SpeechLogRow: View {
  let store: StoreOf<Settings>

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Toggle(
        isOn: Binding(get: { store.speechLogOn }, set: { store.send(.speechLogToggled($0)) })
      ) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Keep a log of what's heard")
            .font(Typography.display(20))
            .foregroundStyle(Palette.ink)
          Text("Words only, never sound, kept on this device until the app closes.")
            .font(Typography.ui(15))
            .foregroundStyle(Palette.muted)
        }
      }
      .tint(Palette.teal)
      HStack(spacing: 12) {
        Text(store.speechLogLines == 1 ? "1 line" : "\(store.speechLogLines) lines")
          .font(Typography.ui(15, weight: .medium))
          .foregroundStyle(Palette.muted)
          .monospacedDigit()
        Spacer()
        if let file = store.speechLogFile {
          ShareLink(item: file) {
            Label("Export", systemImage: "square.and.arrow.up")
          }
          .buttonStyle(.ink(.tertiary))
          Button("Clear", systemImage: "trash") { store.send(.speechLogCleared) }
            .buttonStyle(.ink(.tertiary))
        }
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
    .settingsField()
  }
}

struct SoundRow: View {
  let store: StoreOf<Settings>

  var body: some View {
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
    .settingsField()
  }
}
