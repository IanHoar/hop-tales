#if DEBUG
import ComposableArchitecture
import DesignSystem
import SwiftUI

struct DebugToolsLink: View {
  let store: StoreOf<Settings>

  var body: some View {
    NavigationLink {
      DebugToolsScreen(store: store)
        .toolbar(.hidden, for: .navigationBar)
    } label: {
      HStack {
        Text("Debug tools")
          .font(Typography.display(19))
          .foregroundStyle(Paper.ink)
        Spacer(minLength: 0)
        Image(systemName: "chevron.forward")
          .font(.system(size: 15, weight: .bold))
          .foregroundStyle(Paper.muted)
      }
      .padding(.horizontal, 16)
      .frame(height: 56)
      .settingsField()
      .contentShape(.rect(cornerRadius: 18))
    }
    .buttonStyle(.plain)
  }
}

struct DebugToolsScreen: View {
  let store: StoreOf<Settings>
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 0) {
      header
      ScrollView {
        VStack(alignment: .leading, spacing: 28) {
          SettingsSection("Speech log") { SpeechLogRow(store: store) }
          SettingsSection("Testing") { TestingButtons(store: store) }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 30)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
      }
    }
    .background(Paper.page.ignoresSafeArea())
  }

  private var header: some View {
    HStack(spacing: 12) {
      Button { dismiss() } label: {
        Image(systemName: "chevron.backward")
          .font(.system(size: 17, weight: .bold))
          .foregroundStyle(Paper.ink)
          .frame(width: 40, height: 40)
          .paperChip(Circle(), rim: 3)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Back")
      PaperLabel(seed: 12) {
        Text("Debug")
          .font(Typography.display(22))
          .foregroundStyle(Paper.ink)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
      }
      .rotationEffect(.degrees(-2))
      .accessibilityAddTraits(.isHeader)
      Spacer()
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
  }
}

#Preview("Debug tools") {
  NavigationStack {
    DebugToolsScreen(store: Store(initialState: Settings.State()) { Settings() })
  }
}
#endif
