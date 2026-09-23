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
    public var path: [Step] = []
    public var childName = ""
    public var authorization: SpeechClient.Authorization?
    public var startingStoryID = StoryLibrary.all[0].id
    public var accent = Profile.Accent.canadian
    public var voiceID: String?
    public var voices: [SpeechClient.Voice] = []
    public init() {}

    public init(resuming draft: ProfileDraft) {
      childName = draft.profile.childName
      startingStoryID = draft.profile.startingStoryID
      accent = draft.profile.accent
      voiceID = draft.profile.voiceID
      path = Step.allCases.filter { $0 != .welcome && $0.rawValue <= draft.step }
    }

    public var draft: ProfileDraft {
      ProfileDraft(
        profile: Profile(
          childName: childName,
          startingStoryID: startingStoryID,
          accent: accent,
          voiceID: voiceID
        ),
        step: step.rawValue
      )
    }

    public var profile: Profile {
      Profile(
        childName: childName.trimmingCharacters(in: .whitespacesAndNewlines),
        startingStoryID: startingStoryID,
        accent: accent,
        voiceID: voiceID
      )
    }

    public var step: Step { path.last ?? .welcome }

    func canContinue(from step: Step) -> Bool {
      step != .listening || authorization != nil
    }
  }

  public enum Action {
    case accentPicked(Profile.Accent)
    case authorizationResolved(SpeechClient.Authorization)
    case continueTapped
    case finished(Profile)
    case hearVoiceTapped(String)
    case listenTapped
    case nameChanged(String)
    case pathChanged([Step])
    case storyPicked(String)
    case voicePicked(String)
    case voicesLoaded([SpeechClient.Voice])
  }

  public static let sample = "Hello! Let's read together."

  @Dependency(ProfileStore.self) var profileStore
  @Dependency(SpeechClient.self) var speechClient

  public var body: some Feature {
    Update { state, action in
      switch action {
      case let .accentPicked(accent):
        state.accent = accent
        loadVoices(for: accent)

      case let .authorizationResolved(authorization):
        state.authorization = authorization

      case .continueTapped:
        guard state.canContinue(from: state.step) else { break }
        guard let next = Step(rawValue: state.step.rawValue + 1) else {
          let profile = state.profile
          store.addTask { try store.send(.finished(profile)) }
          break
        }
        state.path.append(next)
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

      case let .pathChanged(path):
        guard path.count < state.path.count else { break }
        state.path = path

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
      profileStore.saveDraft(state.draft)
    }
    .onMount { state in
      if state.step.rawValue > Step.listening.rawValue {
        let locale = state.accent.locale
        store.addTask {
          let authorization = await speechClient.requestAuthorization(locale)
          try store.send(.authorizationResolved(authorization))
        }
      }
      if state.step == .voice { loadVoices(for: state.accent) }
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
    NavigationStack(path: Binding(get: { store.path }, set: { store.send(.pathChanged($0)) })) {
      screen(for: .welcome)
        .navigationDestination(for: Onboarding.Step.self) { step in
          screen(for: step)
        }
    }
    .tint(Palette.ink)
  }

  private func screen(for step: Onboarding.Step) -> some View {
    ScrollView {
      page(for: step)
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
    }
    .scrollBounceBehavior(.basedOnSize)
    .safeAreaInset(edge: .bottom) {
      continueButton(from: step)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    .background(Palette.cream.ignoresSafeArea())
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        StepDots(current: step)
      }
    }
  }

  @ViewBuilder
  private func page(for step: Onboarding.Step) -> some View {
    switch step {
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

  private func continueButton(from step: Onboarding.Step) -> some View {
    let enabled = store.state.canContinue(from: step)
    return Button {
      store.send(.continueTapped)
    } label: {
      Text(continueTitle(for: step))
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

  private func continueTitle(for step: Onboarding.Step) -> String {
    switch step {
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
  state.path = [.name, .listening]
  return OnboardingScreen(store: Store(initialState: state) { Onboarding() })
}

#Preview("Voice") {
  var state = Onboarding.State()
  state.path = [.name, .listening, .story, .voice]
  state.voices = [
    SpeechClient.Voice(id: "ava", name: "Ava"),
    SpeechClient.Voice(id: "samantha", name: "Samantha")
  ]
  state.voiceID = "ava"
  return OnboardingScreen(store: Store(initialState: state) { Onboarding() })
}
