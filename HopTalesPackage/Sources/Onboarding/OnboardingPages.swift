import ComposableArchitecture2
import Content
import DesignSystem
import SpeechRecognition
import SwiftUI

extension Onboarding.Step {
  var title: String {
    switch self {
    case .name: "What should we call you?"
    case .listening: "Can Hop Tales use the microphone?"
    case .story: "What's your reader's reading level?"
    case .accent: "What's your reader's accent?"
    }
  }

  var detail: String {
    switch self {
    case .name:
      "A first name, a nickname or anything familiar is perfect. We use it to say hello, and "
        + "it never leaves this device."
    case .listening:
      "The microphone lets Hop Tales hear your child read, so the hare can hop to the next "
        + "word. Everything is heard on this device. Nothing is recorded, and nothing is sent "
        + "anywhere."
    case .story:
      "Hop Tales starts them on a story that fits. You can change this later."
    case .accent:
      "Hop Tales listens for this accent, so it understands your child's words the way they "
        + "say them."
    }
  }
}

struct StepPage: View {
  let store: StoreOf<Onboarding>

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Step \(store.step.rawValue) of \(Onboarding.Step.allCases.count)")
        .font(Typography.caps(13))
        .tracking(1)
        .textCase(.uppercase)
        .foregroundStyle(Paper.muted)
      Text(store.step.title)
        .font(Typography.display(28))
        .foregroundStyle(Paper.ink)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityAddTraits(.isHeader)
      Text(store.step.detail)
        .font(Typography.ui(16, weight: .medium))
        .foregroundStyle(Paper.ink.opacity(0.85))
        .fixedSize(horizontal: false, vertical: true)
      content
        .padding(.top, 4)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private var content: some View {
    switch store.step {
    case .name:
      NameField(name: store.childName) { store.send(.nameChanged($0)) }
    case .listening:
      MicrophoneNote(authorization: store.authorization)
    case .story:
      LevelChoices(selected: store.startingStoryID) { store.send(.storyPicked($0)) }
    case .accent:
      AccentGrid(selected: store.accent) { store.send(.accentPicked($0)) }
    }
  }
}

struct NameField: View {
  let name: String
  let change: (String) -> Void
  @FocusState private var focused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Name or nickname")
        .font(Typography.ui(14))
        .foregroundStyle(Paper.muted)
      TextField("", text: Binding(get: { name }, set: change))
        .font(Typography.display(22))
        .foregroundStyle(Paper.ink)
        .textContentType(.nickname)
        .autocorrectionDisabled()
        .submitLabel(.done)
        .focused($focused)
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(Paper.rim.opacity(0.7), in: field)
        .overlay(field.strokeBorder(Paper.rim, lineWidth: 3))
        .shadow(color: Paper.shadow.opacity(0.4), radius: 2, y: 1)
        .contentShape(field)
        .onTapGesture { focused = true }
        .accessibilityLabel("Name or nickname")
    }
    .onAppear { focused = true }
  }

  private var field: RoundedRectangle { RoundedRectangle(cornerRadius: 16, style: .continuous) }
}

struct MicrophoneNote: View {
  let authorization: SpeechClient.Authorization?

  var body: some View {
    switch authorization {
    case nil:
      Text("iPhone will ask you to allow the microphone and speech recognition.")
        .font(Typography.ui(13, weight: .medium))
        .foregroundStyle(Paper.muted)
        .fixedSize(horizontal: false, vertical: true)
    case .authorized:
      Label {
        Text("Microphone allowed.")
          .font(Typography.ui(16))
          .foregroundStyle(Paper.sageDeep)
      } icon: {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 22))
          .foregroundStyle(Paper.onRed, Paper.sage)
      }
    case .denied:
      note(
        "The microphone is off. You can allow it later in Settings, under Hop Tales. Until "
          + "then, tap a word to hear it."
      )
    case .unsupported:
      note("This device can't recognise speech on its own, so stories use tap to hear instead.")
    }
  }

  private func note(_ text: String) -> some View {
    Label {
      Text(text)
        .font(Typography.ui(15, weight: .medium))
        .foregroundStyle(Paper.ink)
        .fixedSize(horizontal: false, vertical: true)
    } icon: {
      Image(systemName: "mic.slash").foregroundStyle(Paper.muted)
    }
  }
}

struct LevelChoices: View {
  let selected: String?
  let pick: (String) -> Void

  static let levels: [(name: String, detail: String)] = [
    ("Just starting", "Short, simple words like sun, hid and ran."),
    ("Getting going", "Longer sentences and words like robin and flowers."),
    ("Reading well", "Longer words and ideas, like storm and drifts.")
  ]

  var body: some View {
    VStack(spacing: 10) {
      ForEach(Array(zip(StoryLibrary.all, Self.levels)), id: \.0.id) { story, level in
        PaperChoice(title: level.name, detail: level.detail, isSelected: story.id == selected) {
          pick(story.id)
        }
      }
    }
  }
}

struct AccentGrid: View {
  let selected: Profile.Accent?
  let pick: (Profile.Accent) -> Void

  var body: some View {
    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
      ForEach(Profile.Accent.allCases, id: \.self) { accent in
        PaperChoice(title: accent.name, isSelected: accent == selected) { pick(accent) }
      }
    }
  }
}
