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

struct WelcomeCarousel: View {
  let getStarted: () -> Void
  @State private var slide = 0

  static let slides: [(title: String, detail: String)] = [
    (
      "Reading, out loud",
      "Your child reads each word aloud, and the ball hops to the next one the moment "
        + "they say it."
    ),
    (
      "A world that grows with every word",
      "Each word read moves the story along, from a sunny meadow to a castle and a friendly dragon."
    ),
    (
      "Private by design",
      "Listening happens on this device. Nothing is recorded or sent anywhere, and there "
        + "are no ads."
    )
  ]

  var body: some View {
    VStack(spacing: 0) {
      TabView(selection: $slide) {
        ForEach(Self.slides.indices, id: \.self) { index in
          VStack(spacing: 32) {
            art(for: index)
              .frame(maxWidth: .infinity)
              .frame(height: 300)
            PageTitle(title: Self.slides[index].title, detail: Self.slides[index].detail)
            Spacer(minLength: 0)
          }
          .padding(.horizontal, 24)
          .padding(.top, 24)
          .frame(maxWidth: 560)
          .tag(index)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      SlideDots(count: Self.slides.count, current: slide)
        .padding(.bottom, 24)
      PrimaryButton(title: "Get started", action: getStarted)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    .background(Palette.cream.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
  }

  @ViewBuilder
  private func art(for index: Int) -> some View {
    switch index {
    case 0: HopArt()
    case 1: WorldArt()
    default: PrivacyArt()
    }
  }
}

struct SlideDots: View {
  let count: Int
  let current: Int

  var body: some View {
    HStack(spacing: 8) {
      ForEach(0..<count, id: \.self) { index in
        Capsule()
          .fill(index == current ? Palette.amber : Palette.trackBg)
          .frame(width: index == current ? 22 : 8, height: 8)
      }
    }
    .animation(.easeInOut(duration: 0.2), value: current)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Page \(current + 1) of \(count)")
  }
}

struct HopArt: View {
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 34, style: .continuous)
        .fill(Palette.creamDeep)
      VStack(spacing: 18) {
        Circle()
          .fill(
            RadialGradient(
              colors: [Palette.ballHi, Palette.ball, Palette.ballLo],
              center: UnitPoint(x: 0.35, y: 0.3),
              startRadius: 0,
              endRadius: 40
            )
          )
          .frame(width: 48, height: 48)
        HStack(alignment: .firstTextBaseline, spacing: 14) {
          Text("The")
            .font(Typography.word(22))
            .foregroundStyle(Palette.pillText)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(Palette.pillBg, in: .rect(cornerRadius: 10))
          Text("cat")
            .font(Typography.word(64))
            .foregroundStyle(Palette.ink)
          Text("sat")
            .font(Typography.word(22))
            .foregroundStyle(Palette.muted)
        }
      }
    }
    .accessibilityHidden(true)
  }
}

struct WorldArt: View {
  var body: some View {
    WorldView(progress: 700)
      .clipShape(.rect(cornerRadius: 34, style: .continuous))
      .allowsHitTesting(false)
      .accessibilityHidden(true)
  }
}

struct PrivacyArt: View {
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 34, style: .continuous)
        .fill(Palette.creamDeep)
      HStack(spacing: 22) {
        badge("iphone")
        badge("lock.fill")
        badge("hand.raised.fill")
      }
    }
    .accessibilityHidden(true)
  }

  private func badge(_ symbol: String) -> some View {
    Image(systemName: symbol)
      .font(.system(size: 34, weight: .semibold))
      .foregroundStyle(Palette.amberDeep)
      .frame(width: 84, height: 84)
      .background(Palette.cream, in: .circle)
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
        title: "Can Hop Tales listen while your child reads?",
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
  let selected: String?
  let pick: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      PageTitle(
        title: "Where should your reader start?",
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

struct AccentPage: View {
  let selected: Profile.Accent?
  let pick: (Profile.Accent) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      PageTitle(
        title: "Which English does your reader speak?",
        detail: "Hop Tales listens for this accent, so it hears your child's words the way "
          + "they say them."
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
