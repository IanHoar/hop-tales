import Content
import DesignSystem
import SpeechRecognition
import SwiftUI
import World

struct StepDots: View {
  let current: Onboarding.Step

  var body: some View {
    HStack(spacing: 8) {
      ForEach(Onboarding.Step.setup, id: \.self) { step in
        Capsule()
          .fill(step.rawValue <= current.rawValue ? Palette.amber : Palette.trackBg)
          .frame(width: step == current ? 22 : 8, height: 8)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Step \(current.rawValue) of \(Onboarding.Step.setup.count)")
  }
}

struct PageTitle: View {
  let title: String
  let detail: String

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(Typography.ui(30))
        .foregroundStyle(Palette.ink)
        .fixedSize(horizontal: false, vertical: true)
      Text(detail)
        .font(Typography.ui(17))
        .foregroundStyle(Palette.muted)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct PrimaryButton: View {
  let title: String
  var enabled = true
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(Typography.ui(20))
        .foregroundStyle(Palette.flashText)
        .frame(maxWidth: 560)
        .frame(height: 60)
        .background {
          Capsule()
            .fill(Palette.amber)
            .shadow(color: Palette.amberDeep.opacity(0.6), radius: 0, x: 0, y: 4)
        }
    }
    .buttonStyle(.plain)
    .opacity(enabled ? 1 : 0.45)
    .disabled(!enabled)
  }
}

struct NamePage: View {
  let name: String
  let change: (String) -> Void
  @FocusState private var focused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      PageTitle(
        title: "What's your reader's name?",
        detail: "We use it to say hello on the home screen. It stays on this device."
      )
      TextField("First name", text: Binding(get: { name }, set: change))
        .font(Typography.ui(24))
        .foregroundStyle(Palette.ink)
        .textContentType(.givenName)
        .autocorrectionDisabled()
        .submitLabel(.done)
        .focused($focused)
        .padding(.horizontal, 20)
        .frame(height: 64)
        .background(Palette.creamDeep, in: .rect(cornerRadius: 20))
    }
    .onAppear { focused = true }
  }
}

struct ListeningPage: View {
  let authorization: SpeechClient.Authorization?
  let turnOn: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      PageTitle(
        title: "Can Hop Tales use the microphone?",
        detail: "The microphone lets Hop Tales hear your child read, so the ball can hop to the "
          + "next word. Everything is heard on this device. Nothing is recorded, and nothing is "
          + "sent anywhere."
      )
      switch authorization {
      case nil:
        VStack(alignment: .leading, spacing: 12) {
          Button(action: turnOn) {
            Label("Allow microphone", systemImage: "mic.fill")
              .font(Typography.ui(20))
              .foregroundStyle(Palette.ink)
              .frame(maxWidth: .infinity)
              .frame(height: 60)
              .background(Palette.creamDeep, in: .capsule)
          }
          .buttonStyle(.plain)
          Text("iPhone will ask you to allow the microphone and speech recognition.")
            .font(Typography.ui(14))
            .foregroundStyle(Palette.muted)
            .fixedSize(horizontal: false, vertical: true)
        }
      case .authorized:
        Note(
          symbol: "checkmark.circle.fill",
          colour: Palette.heardText,
          text: "Microphone allowed."
        )
      case .denied:
        Note(
          symbol: "mic.slash",
          colour: Palette.muted,
          text: "The microphone is off. You can allow it later in Settings, under Hop Tales. "
            + "Until then, tap a word to hear it."
        )
      case .unsupported:
        Note(
          symbol: "mic.slash",
          colour: Palette.muted,
          text: "This device can't recognise speech on its own, so stories use tap to hear "
            + "instead."
        )
      }
    }
  }
}

struct Note: View {
  let symbol: String
  let colour: Color
  let text: String

  var body: some View {
    Label {
      Text(text)
        .font(Typography.ui(17))
        .foregroundStyle(Palette.ink)
        .fixedSize(horizontal: false, vertical: true)
    } icon: {
      Image(systemName: symbol).foregroundStyle(colour)
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Palette.creamDeep, in: .rect(cornerRadius: 20))
  }
}

struct StoryPage: View {
  let selected: String?
  let pick: (String) -> Void

  static let levels: [(name: String, detail: String)] = [
    ("Just starting", "Short, simple words like cat, sun and mud."),
    ("Getting going", "Longer sentences and a few tricky words like knight."),
    ("Reading well", "Longer words and ideas, like dragon and purple.")
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      PageTitle(
        title: "What's your reader's reading level?",
        detail: "Hop Tales starts them on a story that fits. You can change this later."
      )
      VStack(spacing: 12) {
        ForEach(Array(zip(StoryLibrary.all, Self.levels)), id: \.0.id) { story, level in
          Choice(
            title: level.name,
            detail: "\(level.detail) Starts with \(story.title).",
            isSelected: story.id == selected
          ) { pick(story.id) }
        }
      }
    }
  }
}

struct AccentPage: View {
  let selected: Profile.Accent?
  let pick: (Profile.Accent) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      PageTitle(
        title: "What's your reader's accent?",
        detail: "Hop Tales listens for this accent, so it understands your child's words the "
          + "way they say them."
      )
      VStack(spacing: 12) {
        ForEach(Profile.Accent.allCases, id: \.self) { accent in
          Choice(title: accent.name, isSelected: accent == selected) { pick(accent) }
        }
      }
    }
  }
}

struct VoicePage: View {
  let voices: [SpeechClient.Voice]
  let selected: String?
  let pick: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      PageTitle(
        title: "Which voice should read words aloud?",
        detail: "When your child needs help, this voice says the word. Tap one to hear it."
      )
      VStack(spacing: 12) {
        ForEach(voices) { voice in
          Choice(title: voice.name, isSelected: voice.id == selected) { pick(voice.id) }
        }
      }
    }
  }
}

struct Choice: View {
  let title: String
  var detail: String?
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(Typography.ui(19))
            .foregroundStyle(Palette.ink)
          if let detail {
            Text(detail)
              .font(Typography.ui(14))
              .foregroundStyle(Palette.muted)
          }
        }
        Spacer()
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .font(.system(size: 24))
          .foregroundStyle(isSelected ? Palette.amberDeep : Palette.faint)
      }
      .padding(.horizontal, 20)
      .frame(minHeight: 64)
      .background(
        isSelected ? Palette.pillBg : Palette.creamDeep,
        in: .rect(cornerRadius: 20)
      )
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}
