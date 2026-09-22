import Content
import DesignSystem
import SpeechRecognition
import SwiftUI

struct StepDots: View {
  let current: Onboarding.Step

  var body: some View {
    HStack(spacing: 8) {
      ForEach(Onboarding.Step.allCases, id: \.self) { step in
        Capsule()
          .fill(step.rawValue <= current.rawValue ? Palette.amber : Palette.trackBg)
          .frame(width: step == current ? 22 : 8, height: 8)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Step \(current.rawValue + 1) of \(Onboarding.Step.allCases.count)")
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

struct WelcomePage: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 28) {
      Circle()
        .fill(
          RadialGradient(
            colors: [Palette.ballHi, Palette.ball, Palette.ballLo],
            center: UnitPoint(x: 0.35, y: 0.3),
            startRadius: 0,
            endRadius: 70
          )
        )
        .frame(width: 88, height: 88)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
      PageTitle(
        title: "Welcome to Hop Tales",
        detail: "Your child reads each word out loud, and the ball hops along with them. "
          + "A grown-up sets up a few things first. It takes about a minute."
      )
    }
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
        title: "Hop Tales listens as your child reads",
        detail: "When they say a word, the ball hops to the next one. Listening happens on this "
          + "device. Nothing is recorded, and nothing is sent anywhere."
      )
      switch authorization {
      case nil:
        Button(action: turnOn) {
          Label("Turn on listening", systemImage: "mic.fill")
            .font(Typography.ui(20))
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Palette.creamDeep, in: .capsule)
        }
        .buttonStyle(.plain)
      case .authorized:
        Note(symbol: "checkmark.circle.fill", colour: Palette.heardText, text: "Listening is on.")
      case .denied:
        Note(
          symbol: "mic.slash",
          colour: Palette.muted,
          text: "Listening is off. You can turn it on later in Settings, under Hop Tales. "
            + "Until then, tap a word to hear it."
        )
      case .unsupported:
        Note(
          symbol: "mic.slash",
          colour: Palette.muted,
          text: "This device can't listen on its own, so stories use tap to hear instead."
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
  let selected: String
  let pick: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      PageTitle(
        title: "Where should they start?",
        detail: "Each story gets a little harder. You can change this later."
      )
      VStack(spacing: 12) {
        ForEach(StoryLibrary.all, id: \.id) { story in
          Choice(
            title: story.title,
            detail: "\(story.sentences.count) sentences",
            isSelected: story.id == selected
          ) { pick(story.id) }
        }
      }
    }
  }
}

struct VoicePage: View {
  let accent: Profile.Accent
  let voices: [SpeechClient.Voice]
  let voiceID: String?
  let pickAccent: (Profile.Accent) -> Void
  let pickVoice: (String) -> Void
  let hear: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      PageTitle(
        title: "How does your reader speak?",
        detail: "Hop Tales listens for this accent, and uses the voice below when your child "
          + "asks to hear a word."
      )
      VStack(spacing: 12) {
        ForEach(Profile.Accent.allCases, id: \.self) { option in
          Choice(title: option.name, isSelected: option == accent) { pickAccent(option) }
        }
      }
      if !voices.isEmpty {
        Text("HELP VOICE")
          .font(Typography.caps(11))
          .tracking(1.76)
          .foregroundStyle(Palette.muted)
          .padding(.top, 8)
        VStack(spacing: 12) {
          ForEach(voices) { voice in
            Choice(title: voice.name, isSelected: voice.id == voiceID) {
              pickVoice(voice.id)
              hear(voice.id)
            }
          }
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
