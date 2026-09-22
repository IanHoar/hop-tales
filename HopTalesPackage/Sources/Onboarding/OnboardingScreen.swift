import ComposableArchitecture2
import Content
import Dependencies
import DesignSystem
import SpeechRecognition
import SwiftUI

@Feature public struct Onboarding {
  public init() {}

  public enum Step: Int, CaseIterable, Hashable, Sendable {
    case welcome
    case name
    case listening
    case story
    case voice
  }

  public struct State {
    public var step = Step.welcome
    public var childName = ""
    public var authorization: SpeechClient.Authorization?
    public var startingStoryID = StoryLibrary.all[0].id
    public var accent = Profile.Accent.canadian
    public var voiceID: String?
    public var voices: [SpeechClient.Voice] = []
    public init() {}

    public var profile: Profile {
      Profile(
        childName: childName.trimmingCharacters(in: .whitespacesAndNewlines),
        startingStoryID: startingStoryID,
        accent: accent,
        voiceID: voiceID
      )
    }

    var canContinue: Bool {
      step != .listening || authorization != nil
    }

    var isLastStep: Bool { step == Step.allCases.last }
  }

  public enum Action {
    case accentPicked(Profile.Accent)
    case authorizationResolved(SpeechClient.Authorization)
    case backTapped
    case continueTapped
    case finished(Profile)
    case hearVoiceTapped(String)
    case listenTapped
    case nameChanged(String)
    case storyPicked(String)
    case voicePicked(String)
    case voicesLoaded([SpeechClient.Voice])
  }

  public static let sample = "Hello! Let's read together."

  @Dependency(SpeechClient.self) var speechClient

  public var body: some Feature {
    Update { state, action in
      switch action {
      case let .accentPicked(accent):
        state.accent = accent
        loadVoices(for: accent)

      case let .authorizationResolved(authorization):
        state.authorization = authorization

      case .backTapped:
        guard let previous = Step(rawValue: state.step.rawValue - 1) else { break }
        state.step = previous

      case .continueTapped:
        guard state.canContinue else { break }
        guard let next = Step(rawValue: state.step.rawValue + 1) else {
          let profile = state.profile
          store.addTask { try store.send(.finished(profile)) }
          break
        }
        state.step = next
        if next == .voice, state.voices.isEmpty { loadVoices(for: state.accent) }

      case .finished:
        break

      case let .hearVoiceTapped(id):
        store.addTask { await speechClient.speak(Self.sample, id) }

      case .listenTapped:
        let locale = state.accent.locale
        store.addTask {
          let authorization = await speechClient.requestAuthorization(locale)
          try store.send(.authorizationResolved(authorization))
        }

      case let .nameChanged(name):
        state.childName = String(name.prefix(24))

      case let .storyPicked(id):
        state.startingStoryID = id

      case let .voicePicked(id):
        state.voiceID = id

      case let .voicesLoaded(voices):
        state.voices = voices
        if !voices.contains(where: { $0.id == state.voiceID }) {
          state.voiceID = voices.first?.id
        }
      }
    }
  }

  private func loadVoices(for accent: Profile.Accent) {
    let locale = accent.locale
    store.addTask {
      let voices = await speechClient.voices(locale)
      try store.send(.voicesLoaded(voices))
    }
  }
}

public struct OnboardingScreen: View {
  let store: StoreOf<Onboarding>

  public init(store: StoreOf<Onboarding>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      header
      ScrollView {
        page
          .padding(.horizontal, 24)
          .padding(.top, 32)
          .frame(maxWidth: 560)
          .frame(maxWidth: .infinity)
      }
      .scrollBounceBehavior(.basedOnSize)
      continueButton
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    .background(Palette.cream.ignoresSafeArea())
    .animation(.easeInOut(duration: 0.25), value: store.step)
  }

  private var header: some View {
    HStack {
      Button {
        store.send(.backTapped)
      } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(Palette.ink)
          .frame(width: 48, height: 48)
          .background(Palette.creamDeep, in: .circle)
      }
      .opacity(store.step == .welcome ? 0 : 1)
      .disabled(store.step == .welcome)
      .accessibilityLabel("Back")
      Spacer()
      StepDots(current: store.step)
      Spacer()
      Color.clear.frame(width: 48, height: 48)
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
  }

  @ViewBuilder
  private var page: some View {
    switch store.step {
    case .welcome:
      WelcomePage()
    case .name:
      NamePage(name: store.childName) { store.send(.nameChanged($0)) }
    case .listening:
      ListeningPage(authorization: store.authorization) { store.send(.listenTapped) }
    case .story:
      StoryPage(selected: store.startingStoryID) { store.send(.storyPicked($0)) }
    case .voice:
      VoicePage(
        accent: store.accent,
        voices: store.voices,
        voiceID: store.voiceID,
        pickAccent: { store.send(.accentPicked($0)) },
        pickVoice: { store.send(.voicePicked($0)) },
        hear: { store.send(.hearVoiceTapped($0)) }
      )
    }
  }

  private var continueButton: some View {
    Button {
      store.send(.continueTapped)
    } label: {
      Text(continueTitle)
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
    .opacity(store.canContinue ? 1 : 0.45)
    .disabled(!store.canContinue)
  }

  private var continueTitle: String {
    switch store.step {
    case .welcome: "Let's set up"
    case .name where store.childName.trimmingCharacters(in: .whitespaces).isEmpty: "Skip for now"
    case .voice: "Start reading"
    default: "Continue"
    }
  }
}

#Preview {
  OnboardingScreen(store: Store(initialState: Onboarding.State()) { Onboarding() })
}

#Preview("Listening") {
  var state = Onboarding.State()
  state.step = .listening
  return OnboardingScreen(store: Store(initialState: state) { Onboarding() })
}

#Preview("Voice") {
  var state = Onboarding.State()
  state.step = .voice
  state.voices = [
    SpeechClient.Voice(id: "ava", name: "Ava"),
    SpeechClient.Voice(id: "samantha", name: "Samantha")
  ]
  state.voiceID = "ava"
  return OnboardingScreen(store: Store(initialState: state) { Onboarding() })
}
