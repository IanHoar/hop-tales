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
    case accent

    public static var setup: [Step] { allCases.filter { $0 != .welcome } }
  }

  public struct State {
    public var path: [Step] = []
    public var childName = ""
    public var authorization: SpeechClient.Authorization?
    public var startingStoryID: String?
    public var accent: Profile.Accent?
    public init() {}

    public init(resuming draft: ProfileDraft) {
      childName = draft.childName
      startingStoryID = draft.startingStoryID
      accent = draft.accent
      path = Step.allCases.filter { $0 != .welcome && $0.rawValue <= draft.step }
    }

    public var draft: ProfileDraft {
      ProfileDraft(
        childName: childName,
        startingStoryID: startingStoryID,
        accent: accent,
        step: step.rawValue
      )
    }

    public var isComplete: Bool {
      step == Step.allCases.last
        && Step.setup.filter { $0 != .listening }.allSatisfy(canContinue(from:))
    }

    var listeningLocale: Locale { (accent ?? .canadian).locale }

    public var profile: Profile {
      Profile(
        childName: childName.trimmingCharacters(in: .whitespacesAndNewlines),
        startingStoryID: startingStoryID ?? StoryLibrary.all[0].id,
        accent: accent ?? .canadian
      )
    }

    public var step: Step { path.last ?? .welcome }

    func canContinue(from step: Step) -> Bool {
      switch step {
      case .welcome: true
      case .name: !childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      case .listening: authorization != nil
      case .story: startingStoryID != nil
      case .accent: accent != nil
      }
    }
  }

  public enum Action {
    case accentPicked(Profile.Accent)
    case authorizationResolved(SpeechClient.Authorization)
    case continueTapped
    case finished(Profile)
    case listenTapped
    case nameChanged(String)
    case pathChanged([Step])
    case storyPicked(String)
  }

  @Dependency(ProfileStore.self) var profileStore
  @Dependency(SpeechClient.self) var speechClient

  public var body: some Feature {
    Update { state, action in
      switch action {
      case let .accentPicked(accent):
        state.accent = accent

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

      case .finished:
        break

      case .listenTapped:
        let locale = state.listeningLocale
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

      }
      profileStore.saveDraft(state.draft)
    }
    .onMount { state in
      if state.step.rawValue > Step.listening.rawValue {
        let locale = state.listeningLocale
        store.addTask {
          let authorization = await speechClient.requestAuthorization(locale)
          try store.send(.authorizationResolved(authorization))
        }
      }
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
      WelcomeCarousel { store.send(.continueTapped) }
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
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(Palette.cream)
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
      EmptyView()
    case .name:
      NamePage(name: store.childName) { store.send(.nameChanged($0)) }
    case .listening:
      ListeningPage(authorization: store.authorization) { store.send(.listenTapped) }
    case .story:
      StoryPage(selected: store.startingStoryID) { store.send(.storyPicked($0)) }
    case .accent:
      AccentPage(selected: store.accent) { store.send(.accentPicked($0)) }
    }
  }

  private func continueButton(from step: Onboarding.Step) -> some View {
    PrimaryButton(
      title: continueTitle(for: step),
      enabled: store.state.canContinue(from: step)
    ) {
      store.send(.continueTapped)
    }
  }

  private func continueTitle(for step: Onboarding.Step) -> String {
    switch step {
    case .welcome: "Get started"
    case .accent: "Start reading"
    default: "Next"
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

#Preview("Reading level") {
  var state = Onboarding.State()
  state.path = [.name, .listening, .story]
  return OnboardingScreen(store: Store(initialState: state) { Onboarding() })
}
