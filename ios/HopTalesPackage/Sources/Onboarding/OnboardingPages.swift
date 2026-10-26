import ComposableArchitecture
import Content
import DesignSystem
import SpeechRecognition
import SwiftUI
import World

extension Onboarding.Step {
  var title: String {
    switch self {
    case .name: "What should we call you?"
    case .listening: "Can Hop Tales use the microphone?"
    case .ahead: "Reading grows with your reader"
    case .soundButtons: "Show dots and dashes under the sounds?"
    case .cloud: "Use Hop Tales with iCloud?"
    }
  }

  var detail: String {
    switch self {
    case .name:
      "A first name, a nickname or anything familiar is perfect. We use it to say hello, and "
        + "it's never sent to us."
    case .listening:
      "The microphone lets Hop Tales hear your child read, so the hare can hop to the next "
        + "word. Everything is heard on this device. Nothing is recorded, and nothing is sent "
        + "anywhere."
    case .ahead:
      "Your reader starts with \(Friend.at(level: 1).name) and short, simple words. With every "
        + "story they read, they'll meet new friends and move on to longer, trickier words."
    case .soundButtons:
      "Sound buttons put a dot under each sound and a dash under letters that make one sound "
        + "together, like sh. Many schools teach blending this way. You can change this later."
    case .cloud:
      "Already reading with Hop Tales on another iPhone or iPad? Choose Yes to bring back "
        + "your reader's name and progress. From then on, progress is saved to your own iCloud "
        + "as they read. Only you can see it. We never do. You can change this later."
    }
  }
}

struct WelcomePage: View {
  static let summary =
    "Your child reads each word out loud, and the hare hops along the path to the next one. "
    + "Hop Tales listens on this device. Nothing is recorded or sent anywhere."

  static let steps = [
    "Bring back a reader from iCloud, if you have one",
    "Your reader's name",
    "Let Hop Tales listen",
    "How reading grows",
    "Dots and dashes under the sounds"
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Before you start")
        .font(Typography.caps(13))
        .tracking(1)
        .textCase(.uppercase)
        .foregroundStyle(Paper.muted)
      Text("Welcome to Hop Tales")
        .font(Typography.display(28))
        .foregroundStyle(Paper.ink)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityAddTraits(.isHeader)
      Text(Self.summary)
        .font(Typography.ui(16, weight: .medium))
        .foregroundStyle(Paper.ink.opacity(0.85))
        .fixedSize(horizontal: false, vertical: true)
      VStack(alignment: .leading, spacing: 10) {
        Text("Setting up takes about a minute:")
          .font(Typography.ui(16, weight: .semibold))
          .foregroundStyle(Paper.ink)
        ForEach(Array(Self.steps.enumerated()), id: \.offset) { index, step in
          WelcomeStep(number: index + 1, text: step)
        }
      }
      .padding(.top, 4)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct WelcomeStep: View {
  let number: Int
  let text: String

  var body: some View {
    HStack(spacing: 12) {
      Text("\(number)")
        .font(Typography.ui(14, weight: .bold))
        .foregroundStyle(Paper.ink)
        .frame(width: 26, height: 26)
        .background(Paper.rim.opacity(0.7), in: Circle())
      Text(text)
        .font(Typography.ui(16, weight: .medium))
        .foregroundStyle(Paper.ink.opacity(0.85))
        .fixedSize(horizontal: false, vertical: true)
    }
    .accessibilityElement(children: .combine)
  }
}

struct StepPage: View {
  let store: StoreOf<Onboarding>

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Step \(store.stepNumber) of \(store.steps.count)")
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
      NameField(name: store.childName) {
        store.send(.nameChanged($0))
      } submit: {
        if store.primaryEnabled { store.send(.primaryTapped) }
      }
    case .listening:
      MicrophoneNote(authorization: store.authorization)
    case .ahead:
      ReadingAhead(childName: store.childName)
    case .soundButtons:
      SoundButtonChoices(selected: store.soundButtons) { store.send(.soundButtonsPicked($0)) }
    case .cloud:
      CloudChoices(selected: store.cloudSync, account: store.cloudAccount) {
        store.send(.cloudSyncPicked($0))
      }
    }
  }
}

struct NameField: View {
  let name: String
  let change: @MainActor (String) -> Void
  let submit: @MainActor () -> Void
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
        .onSubmit(submit)
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(Paper.rim.opacity(0.7), in: field)
        .overlay(field.strokeBorder(Paper.rim, lineWidth: 3))
        .shadow(color: Paper.shadow.opacity(0.4), radius: 2, y: 1)
        .contentShape(field)
        .onTapGesture { focused = true }
        .accessibilityLabel("Name or nickname")
    }
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

struct ReadingAhead: View {
  let childName: String

  private let friends = (1...3).map { Friend.at(level: $0) }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(friends, id: \.self) { friend in
        if friend != friends.first { Trail() }
        FriendAhead(friend: friend, startsHere: friend == friends.first, childName: childName)
      }
      Trail()
      HStack(spacing: 14) {
        Color.clear.frame(width: 58, height: 1)
        Text("More friends further along")
          .font(Typography.ui(14, weight: .medium))
          .foregroundStyle(Paper.muted)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct FriendAhead: View {
  let friend: Friend
  let startsHere: Bool
  let childName: String

  var body: some View {
    HStack(spacing: 14) {
      FriendSticker(friend, height: 58)
        .frame(width: 58)
      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(friend.name)
            .font(Typography.display(19))
            .foregroundStyle(Paper.ink)
          if startsHere {
            Text("Starts here")
              .font(Typography.ui(12, weight: .semibold))
              .foregroundStyle(Paper.ink)
              .padding(.horizontal, 8)
              .padding(.vertical, 3)
              .background(Paper.wash, in: Capsule())
          }
        }
        Text("Words like \(Text(words).font(Typography.word(18)).foregroundStyle(Paper.ink))")
          .font(Typography.ui(14))
          .foregroundStyle(Paper.muted)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(label)
  }

  private var words: String { friend.examples.joined(separator: ", ") }

  private var label: String {
    let start = startsHere ? ", where \(reader) starts" : ""
    return "\(friend.name)\(start). Words like \(words)."
  }

  private var reader: String {
    let name = childName.trimmingCharacters(in: .whitespacesAndNewlines)
    return name.isEmpty ? "your reader" : name
  }
}

struct Trail: View {
  var body: some View {
    VStack(spacing: 5) {
      ForEach(0..<3, id: \.self) { _ in
        Circle()
          .fill(Paper.muted.opacity(0.45))
          .frame(width: 5, height: 5)
      }
    }
    .frame(width: 58)
    .padding(.vertical, 6)
    .accessibilityHidden(true)
  }
}

struct SoundButtonChoices: View {
  let selected: Bool?
  let pick: (Bool) -> Void

  var body: some View {
    VStack(spacing: 14) {
      SoundMarksExamples()
        .padding(.vertical, 14)
        .paperChoice(isSelected: false)
      ChoicePair {
        PaperChoice(title: "Yes, show them", isSelected: selected == true) { pick(true) }
        PaperChoice(title: "No thanks", isSelected: selected == false) { pick(false) }
      }
    }
  }
}

struct CloudChoices: View {
  let selected: Bool?
  let account: CloudSync.Account?
  let pick: (Bool) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      ChoicePair {
        PaperChoice(title: "Yes, use iCloud", isSelected: selected == true) { pick(true) }
        PaperChoice(title: "Not now", isSelected: selected == false) { pick(false) }
      }
      if account == .signedOut {
        Text(
          "This device isn't signed in to iCloud. Sign in from the Settings app and progress "
            + "will start saving."
        )
        .font(Typography.ui(13, weight: .medium))
        .foregroundStyle(Paper.muted)
        .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

struct ChoicePair<Content: View>: View {
  @ViewBuilder let content: Content

  var body: some View {
    ViewThatFits(in: .horizontal) {
      HStack(spacing: 10) { content }
      VStack(spacing: 10) { content }
    }
  }
}
