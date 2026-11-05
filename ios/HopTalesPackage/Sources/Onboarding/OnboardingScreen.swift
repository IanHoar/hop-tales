import ComposableArchitecture
import Content
import Dependencies
import DesignSystem
import SpeechRecognition
import SwiftUI
import World

@Feature public struct Onboarding {
  public init() {}

  public enum Step: Int, CaseIterable, Hashable, Sendable {
    case cloud = 1
    case name
    case listening
    case ahead
    case soundButtons
  }

  public struct State {
    public var path: [Step] = []
    public var childName = ""
    public var authorization: SpeechClient.Authorization?
    public var accent: Profile.Accent?
    public var soundButtons: Bool?
    public var cloudSync: Bool?
    public var cloudAccount: CloudSync.Account?
    public var isCatchingUp = false
    public var restored: Profile?
    public var isWelcoming = false
    public init() {}

    public init(welcoming: Bool) {
      isWelcoming = welcoming
    }

    public init(resuming draft: ProfileDraft) {
      childName = draft.childName
      accent = draft.accent
      soundButtons = draft.soundButtons
      cloudSync = draft.cloudSync
      path = Step.allCases.filter { $0 != .cloud && $0.rawValue <= draft.step }
    }

    public var draft: ProfileDraft {
      ProfileDraft(
        childName: childName,
        accent: accent,
        soundButtons: soundButtons,
        cloudSync: cloudSync,
        step: step.rawValue
      )
    }

    public var isComplete: Bool {
      step == Step.allCases.last
        && Step.allCases.filter { $0 != .listening }.allSatisfy(canContinue(from:))
    }

    public var step: Step { path.last ?? .cloud }

    public var steps: [Step] { restored == nil ? Step.allCases : [.cloud, .listening] }

    public var stepNumber: Int { (steps.firstIndex(of: step) ?? 0) + 1 }

    public var needsMicrophone: Bool { step == .listening && authorization == nil }

    public var primaryTitle: String {
      if isWelcoming { return "Get started" }
      if needsMicrophone { return "Allow microphone" }
      if isCatchingUp { return "Checking iCloud…" }
      let isLast = step == Step.allCases.last || (restored != nil && step == .listening)
      return isLast ? "Start reading" : "Continue"
    }

    public var primaryEnabled: Bool {
      isWelcoming || needsMicrophone || (canContinue(from: step) && !isCatchingUp)
    }

    func canContinue(from step: Step) -> Bool {
      switch step {
      case .name: !childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      case .listening: authorization != nil
      case .ahead: true
      case .soundButtons: soundButtons != nil
      case .cloud: cloudSync != nil
      }
    }
  }

  public enum Action {
    case authorizationResolved(SpeechClient.Authorization)
    case backTapped
    case pathPopped(to: Int)
    case cloudAccountResolved(CloudSync.Account)
    case cloudCaughtUp(restored: Profile?)
    case cloudSyncPicked(Bool)
    case finished(Profile)
    case nameChanged(String)
    case primaryTapped
    case soundButtonsPicked(Bool)
  }

  @Dependency(\.locale) var locale
  @Dependency(CloudSync.self) var cloudSync
  @Dependency(ProfileStore.self) var profileStore
  @Dependency(SpeechClient.self) var speechClient

  public var body: some Feature {
    Update { state, action in
      switch action {
      case let .authorizationResolved(authorization):
        state.authorization = authorization

      case .backTapped:
        guard !state.path.isEmpty else {
          state.isWelcoming = true
          break
        }
        state.path.removeLast()
        if state.path.isEmpty { state.restored = nil }

      case let .pathPopped(count):
        guard count < state.path.count else { break }
        state.path.removeLast(state.path.count - count)
        if state.path.isEmpty { state.restored = nil }

      case let .cloudAccountResolved(account):
        state.cloudAccount = account

      case let .cloudCaughtUp(restored):
        state.isCatchingUp = false
        state.restored = restored
        state.path.append(restored == nil ? .name : .listening)

      case let .cloudSyncPicked(isOn):
        state.cloudSync = isOn
        if isOn, state.cloudAccount == nil { checkCloudAccount() }

      case .finished:
        break

      case .primaryTapped:
        if state.isWelcoming {
          state.isWelcoming = false
          let draft = state.draft
          store.addTask { profileStore.saveDraft(draft) }
          break
        }
        if state.needsMicrophone {
          let locale = state.listeningLocale(region: self.locale.region)
          store.addTask {
            let authorization = await speechClient.requestAuthorization(locale)
            try store.send(.authorizationResolved(authorization))
          }
          break
        }
        guard state.primaryEnabled else { break }
        if state.step == .cloud, state.cloudSync == true {
          restore(&state)
          break
        }
        if state.step == .listening, let restored = state.restored {
          store.addTask { try store.send(.finished(restored)) }
          break
        }
        guard let next = Step(rawValue: state.step.rawValue + 1) else {
          let profile = state.profile(region: self.locale.region)
          store.addTask { try store.send(.finished(profile)) }
          break
        }
        state.path.append(next)

      case let .nameChanged(name):
        state.childName = String(name.prefix(24))

      case let .soundButtonsPicked(isOn):
        state.soundButtons = isOn

      }
    }
    .onChange(of: store.draft) { _, draft, _ in
      store.addTask { profileStore.saveDraft(draft) }
    }
    .onMount { state in
      if state.step.rawValue > Step.listening.rawValue {
        let locale = state.listeningLocale(region: self.locale.region)
        store.addTask {
          let authorization = await speechClient.requestAuthorization(locale)
          try store.send(.authorizationResolved(authorization))
        }
      }
    }
  }

  private func checkCloudAccount() {
    store.addTask {
      let account = await cloudSync.account()
      try store.send(.cloudAccountResolved(account))
    }
  }

  private func restore(_ state: inout State) {
    state.isCatchingUp = true
    store.addTask {
      await cloudSync.turnOnAndCatchUp()
      let restored = profileStore.load()
      if let restored, speechClient.isAuthorized() {
        try store.send(.finished(restored))
      } else {
        try store.send(.cloudCaughtUp(restored: restored))
      }
    }
  }
}

public struct OnboardingScreen: View {
  let store: StoreOf<Onboarding>
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.simulatedFold) private var simulatedFold

  public init(store: StoreOf<Onboarding>) {
    self.store = store
  }

  public var body: some View {
    GeometryReader { proxy in
      let insets = proxy.safeAreaInsets
      let screen = proxy.size.height + insets.top + insets.bottom
      let area = CGSize(width: proxy.size.width, height: proxy.size.height + insets.bottom)
      let fold = proxy.fold(or: simulatedFold)
      let room = fold?.room(in: area)
      let top = max(insets.top, room?.minY ?? 0) + 12
      let fill = min(room.map { $0.maxY - top } ?? .infinity, screen * 0.61)
      ZStack(alignment: .bottom) {
        MeadowBackdrop(progress: 700, mood: meadowMood)
        if let fold, !fold.runsAcross {
          hare(on: fold.stage(in: area))
        }
        SheetFit(fill: fill) {
          OnboardingSheet(store: store, bottomInset: insets.bottom, scrolls: true)
          OnboardingSheet(store: store, bottomInset: insets.bottom, scrolls: false)
            .hidden()
            .accessibilityHidden(true)
        }
        .animation(.easeInOut(duration: 0.35), value: store.path)
        .animation(.easeInOut(duration: 0.35), value: store.isWelcoming)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        .liftsAboveKeyboard()
        .padding(.top, top)
        .padding(.leading, room?.minX ?? 0)
        .padding(.trailing, room.map { proxy.size.width - $0.maxX } ?? 0)
      }
      .frame(maxWidth: .infinity)
      .ignoresSafeArea(.container, edges: .bottom)
    }
    .ignoresSafeArea(.keyboard)
  }

  private func hare(on stage: CGRect) -> some View {
    let height = min(160, stage.width * 0.5)
    return IdleFriend(.hare, look: nil, height: height)
      .shadow(color: Paper.shadow, radius: 6, y: 4)
      .position(x: stage.midX, y: stage.maxY * 0.86 - height / 2)
      .frame(width: stage.maxX, height: stage.maxY)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }

  private var meadowMood: Mood {
    colorScheme == .dark ? Mood(sky: .night) : Mood(sky: .day)
  }
}

struct OnboardingSheet: View {
  let store: StoreOf<Onboarding>
  let bottomInset: CGFloat
  let scrolls: Bool
  @State private var shown = 0

  private var position: Int { store.isWelcoming ? 0 : store.stepNumber }

  private var slide: AnyTransition {
    let forward = position >= shown
    return .asymmetric(
      insertion: .move(edge: forward ? .trailing : .leading),
      removal: .move(edge: forward ? .leading : .trailing)
    )
  }

  var body: some View {
    VStack(spacing: 16) {
      header
      if scrolls {
        navigator
      } else {
        current
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

  @ViewBuilder
  private var current: some View {
    if store.isWelcoming {
      WelcomePage()
    } else {
      StepPage(store: store, step: store.step)
    }
  }

  private var path: Binding<[Onboarding.Step]> {
    Binding(
      get: { store.isWelcoming ? [] : store.path },
      set: { path in
        store.send(.pathPopped(to: path.count))
      }
    )
  }

  private var navigator: some View {
    NavigationStack(path: path) {
      ZStack(alignment: .top) {
        Group {
          if store.isWelcoming {
            WelcomePage()
          } else {
            StepPage(store: store, step: .cloud)
          }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Paper.paper)
        .id(position == 0)
        .transition(slide)
      }
      .clipped()
      .animation(.easeInOut(duration: 0.35), value: store.isWelcoming)
      .onChange(of: position) { _, now in shown = now }
      .scrolling()
      .navigationDestination(for: Onboarding.Step.self) { step in
        StepPage(store: store, step: step).scrolling()
      }
    }
    .padding(.horizontal, -24)
  }

  private var header: some View {
    ZStack {
      if !store.isWelcoming {
        ProgressPills(current: store.stepNumber - 1, count: store.steps.count)
        backButton
      }
    }
    .frame(height: 24)
  }

  private var backButton: some View {
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

#Preview {
  OnboardingScreen(store: Store(initialState: Onboarding.State()) { Onboarding() })
}
