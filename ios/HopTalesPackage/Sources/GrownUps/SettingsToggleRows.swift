import ComposableArchitecture
import DesignSystem
import SwiftUI
import World

struct SpeechLogRow: View {
  let store: StoreOf<Settings>

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      VStack(alignment: .leading, spacing: 4) {
        Text("What's heard")
          .font(Typography.display(20))
          .foregroundStyle(Paper.ink)
        Text(
          "Debug builds log every word recognised. Words only, never sound, until the app closes."
        )
          .font(Typography.ui(15))
          .foregroundStyle(Paper.muted)
      }
      HStack(spacing: 12) {
        Text(store.speechLogLines == 1 ? "1 line" : "\(store.speechLogLines) lines")
          .font(Typography.ui(15, weight: .medium))
          .foregroundStyle(Paper.muted)
          .monospacedDigit()
        Spacer()
        Group {
          ShareLink(item: Settings.speechLogFile) {
            Label("Export", systemImage: "square.and.arrow.up")
          }
          Button("Clear", systemImage: "trash") { store.send(.speechLogCleared) }
        }
        .buttonStyle(.paperChip)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
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
          .foregroundStyle(Paper.ink)
        Text("The chime when a sentence is finished.")
          .font(Typography.ui(15))
          .foregroundStyle(Paper.muted)
      }
    }
    .tint(Paper.sageDeep)
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .settingsField()
  }
}

struct SettingsHeader: View {
  let done: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      PaperLabel(seed: 11) {
        Text("Settings")
          .font(Typography.display(22))
          .foregroundStyle(Paper.ink)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
      }
      .rotationEffect(.degrees(-2))
      .accessibilityAddTraits(.isHeader)
      Spacer()
      Button("Done", action: done)
        .font(Typography.display(17))
        .foregroundStyle(Paper.ink)
        .padding(.horizontal, 16)
        .frame(height: 40)
        .paperChip(Capsule(), rim: 3)
        .buttonStyle(.plain)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
  }
}

struct TestingButtons: View {
  let store: StoreOf<Settings>

  var body: some View {
    VStack(spacing: 10) {
      row("Reset onboarding", "arrow.counterclockwise") { store.send(.resetOnboardingTapped) }
      row("Reset reading journey", "arrow.uturn.backward") {
        store.send(.debugResetJourneyTapped)
      }
      row("Unlock everything", "lock.open") { store.send(.debugUnlockEverythingTapped) }
    }
  }

  private func row(
    _ title: String, _ icon: String, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Image(systemName: icon)
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(Paper.muted)
          .frame(width: 24)
        Text(title)
          .font(Typography.display(19))
          .foregroundStyle(Paper.ink)
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 16)
      .frame(height: 56)
      .settingsField()
      .contentShape(.rect(cornerRadius: 18))
    }
    .buttonStyle(.plain)
  }
}

struct SoundButtonsRow: View {
  let store: StoreOf<Settings>

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Toggle(
        isOn: Binding(
          get: { store.profile.soundButtons }, set: { store.send(.soundButtonsToggled($0)) }
        )
      ) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Dots and dashes under words")
            .font(Typography.display(20))
            .foregroundStyle(Paper.ink)
          Text("A dot for each sound, a dash for letters that make one sound together.")
            .font(Typography.ui(15))
            .foregroundStyle(Paper.muted)
        }
      }
      .tint(Paper.sageDeep)
      SoundMarksExamples(size: 26)
        .padding(.vertical, 4)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .settingsField()
  }
}

struct SettingsSection<Content: View>: View {
  let title: String
  let content: Content

  init(_ title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title.uppercased())
        .font(Typography.ui(13, weight: .semibold))
        .tracking(13 * 0.14)
        .foregroundStyle(Paper.muted)
        .padding(.horizontal, 4)
        .accessibilityAddTraits(.isHeader)
      content
    }
  }
}

extension View {
  func settingsField() -> some View {
    let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
    return background(Paper.rim.opacity(0.6), in: shape)
      .overlay(shape.strokeBorder(Paper.rim, lineWidth: 3))
      .shadow(color: Paper.shadow.opacity(0.5), radius: 3, y: 2)
  }
}
