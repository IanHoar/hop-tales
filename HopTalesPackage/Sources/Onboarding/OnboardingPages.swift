import ComposableArchitecture2
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
    case .friend: "Who should your reader start with?"
    case .soundButtons: "Show dots and dashes under the sounds?"
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
    case .friend:
      "Pick the friend whose words look about right, and let your reader have a look too. "
        + "You can change this later."
    case .soundButtons:
      "Sound buttons put a dot under each sound and a dash under letters that make one sound "
        + "together, like sh. Many schools teach blending this way. You can change this later."
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
      NameField(name: store.childName) {
        store.send(.nameChanged($0))
      } submit: {
        if store.primaryEnabled { store.send(.primaryTapped) }
      }
    case .listening:
      MicrophoneNote(authorization: store.authorization)
    case .friend:
      FriendChoices(selected: store.startingFriend) { store.send(.friendPicked($0)) }
    case .soundButtons:
      SoundButtonChoices(selected: store.soundButtons) { store.send(.soundButtonsPicked($0)) }
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

struct FriendChoices: View {
  let selected: Friend?
  let pick: (Friend) -> Void

  var body: some View {
    VStack(spacing: 10) {
      ForEach(Friend.starters, id: \.self) { friend in
        FriendChoice(friend: friend, isSelected: friend == selected) { pick(friend) }
      }
      LaterFriends()
        .padding(.top, 6)
    }
  }
}

struct FriendChoice: View {
  let friend: Friend
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 14) {
        FriendSticker(friend, height: 58)
          .frame(width: 58)
        VStack(alignment: .leading, spacing: 2) {
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(friend.name)
              .font(Typography.display(19))
              .foregroundStyle(Paper.ink)
            Text(friend.stage)
              .font(Typography.ui(14))
              .foregroundStyle(Paper.muted)
          }
          Text(friend.examples.joined(separator: " · "))
            .font(Typography.word(18))
            .foregroundStyle(Paper.ink.opacity(0.85))
        }
      }
      .paperChoice(isSelected: isSelected)
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      "\(friend.name), \(friend.stage). Words like \(friend.examples.joined(separator: ", "))."
    )
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
  }
}

struct LaterFriends: View {
  var body: some View {
    VStack(spacing: 6) {
      HStack(alignment: .bottom, spacing: 12) {
        ForEach(Friend.allCases.filter { !Friend.starters.contains($0) }, id: \.self) { friend in
          FriendSticker(friend, height: 34, isSilhouette: true)
            .opacity(0.45)
        }
      }
      Text("\(Friend.allCases.count - Friend.starters.count) more friends join as your reader "
        + "gets stronger")
        .font(Typography.ui(13, weight: .medium))
        .foregroundStyle(Paper.muted)
        .multilineTextAlignment(.center)
      Text(Phonics.standard)
        .font(Typography.ui(12))
        .foregroundStyle(Paper.muted)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .combine)
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
      HStack(spacing: 10) {
        PaperChoice(title: "Yes, show them", isSelected: selected == true) { pick(true) }
        PaperChoice(title: "No thanks", isSelected: selected == false) { pick(false) }
      }
    }
  }
}
