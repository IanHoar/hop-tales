import ComposableArchitecture2
import Content
import Dependencies
import DesignSystem
import SpeechRecognition
import SwiftUI
import World

@Feature public struct Onboarding {
  public init() {}

  public enum Step: Int, CaseIterable, Hashable, Sendable {
    case name = 1
    case listening
    case friend
    case accent
  }

  public struct State {
    public var path: [Step] = []
    public var childName = ""
    public var authorization: SpeechClient.Authorization?
    public var startingFriend: Friend?
    public var accent: Profile.Accent?
    public init() {}

    public init(resuming draft: ProfileDraft) {
      childName = draft.childName
      startingFriend = draft.startingFriend
      accent = draft.accent
      path = Step.allCases.filter { $0 != .name && $0.rawValue <= draft.step }
    }

    public var draft: ProfileDraft {
      ProfileDraft(
        childName: childName,
        startingFriend: startingFriend,
        accent: accent,
        step: step.rawValue
      )
    }

    public var isComplete: Bool {
      step == Step.allCases.last
        && Step.allCases.filter { $0 != .listening }.allSatisfy(canContinue(from:))
    }

    var listeningLocale: Locale { (accent ?? .canadian).locale }

    public var profile: Profile {
      Profile(
        childName: childName.trimmingCharacters(in: .whitespacesAndNewlines),
        startingFriend: startingFriend ?? .bunny,
        accent: accent ?? .canadian
      )
    }

    public var step: Step { path.last ?? .name }

    public var needsMicrophone: Bool { step == .listening && authorization == nil }

    public var primaryTitle: String {
      if needsMicrophone { return "Allow microphone" }
      return step == .accent ? "Start reading" : "Continue"
    }

    public var primaryEnabled: Bool { needsMicrophone || canContinue(from: step) }

    func canContinue(from step: Step) -> Bool {
      switch step {
      case .name: !childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      case .listening: authorization != nil
      case .friend: startingFriend != nil
      case .accent: accent != nil
      }
    }
  }

  public enum Action {
    case accentPicked(Profile.Accent)
    case authorizationResolved(SpeechClient.Authorization)
    case backTapped
    case finished(Profile)
    case friendPicked(Friend)
    case nameChanged(String)
    case primaryTapped
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

      case .backTapped:
        guard !state.path.isEmpty else { break }
        state.path.removeLast()

      case .finished:
        break

      case .primaryTapped:
        if state.needsMicrophone {
          let locale = state.listeningLocale
          store.addTask {
            let authorization = await speechClient.requestAuthorization(locale)
            try store.send(.authorizationResolved(authorization))
          }
          break
        }
        guard state.canContinue(from: state.step) else { break }
        guard let next = Step(rawValue: state.step.rawValue + 1) else {
          let profile = state.profile
          store.addTask { try store.send(.finished(profile)) }
          break
        }
        state.path.append(next)

      case let .nameChanged(name):
        state.childName = String(name.prefix(24))

      case let .friendPicked(friend):
        state.startingFriend = friend

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
  @Environment(\.colorScheme) private var colorScheme

  public init(store: StoreOf<Onboarding>) {
    self.store = store
  }

  public var body: some View {
    GeometryReader { proxy in
      let insets = proxy.safeAreaInsets
      let screen = proxy.size.height + insets.top + insets.bottom
      ZStack(alignment: .bottom) {
        MeadowBackdrop(progress: 700, mood: meadowMood)
        ViewThatFits(in: .vertical) {
          OnboardingSheet(store: store, bottomInset: insets.bottom, scrolls: false)
            .frame(minHeight: screen * 0.61, alignment: .top)
            .fixedSize(horizontal: false, vertical: true)
          OnboardingSheet(store: store, bottomInset: insets.bottom, scrolls: true)
        }
        .frame(maxWidth: 560)
        .liftsAboveKeyboard(keepingTopBelow: insets.top + 12)
        .padding(.top, insets.top + 12)
      }
      .frame(maxWidth: .infinity)
      .ignoresSafeArea(.container, edges: .bottom)
    }
    .ignoresSafeArea(.keyboard)
  }

  private var meadowMood: Mood {
    colorScheme == .dark ? Mood(sky: .night) : Mood(sky: .day)
  }
}

struct OnboardingSheet: View {
  let store: StoreOf<Onboarding>
  let bottomInset: CGFloat
  let scrolls: Bool

  var body: some View {
    VStack(spacing: 16) {
      header
      if scrolls {
        ScrollView { page }
          .scrollBounceBehavior(.basedOnSize)
          .scrollIndicators(.hidden)
          .scrollEdgeEffectHidden(true, for: .all)
      } else {
        page
        Spacer(minLength: 0)
      }
      Button(store.primaryTitle) { store.send(.primaryTapped) }
        .buttonStyle(.paper)
        .disabled(!store.primaryEnabled)
    }
    .padding(.horizontal, 24)
    .padding(.top, 22)
    .padding(.bottom, max(bottomInset, 16) + 8)
    .background {
      Deckle(seed: 21, jitter: 3, step: 16)
        .fill(Paper.paper)
        .padding(.bottom, -12)
        .shadow(color: Paper.shadow, radius: 10, y: -4)
    }
    .tint(Paper.ink)
  }

  private var page: some View {
    StepPage(store: store)
      .id(store.step)
      .transition(
        .asymmetric(insertion: .offset(x: 18).combined(with: .opacity), removal: .opacity)
      )
      .animation(.easeOut(duration: 0.35), value: store.step)
  }

  private var header: some View {
    ZStack {
      ProgressPills(current: store.step.rawValue - 1, count: Onboarding.Step.allCases.count)
      if store.step != .name {
        Button {
          store.send(.backTapped)
        } label: {
          Image(systemName: "chevron.backward")
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(Paper.ink)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Back")
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, -12)
      }
    }
    .frame(height: 24)
  }
}

#Preview {
  OnboardingScreen(store: Store(initialState: Onboarding.State()) { Onboarding() })
}
