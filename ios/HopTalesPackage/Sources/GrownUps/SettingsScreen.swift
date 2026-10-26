import ComposableArchitecture
import Content
import Dependencies
import DesignSystem
import SpeechRecognition
import SwiftUI
import World

@Feature public struct Settings {
  public static let sample = "Let's read together!"

  public init() {}

  public enum CloudNote: Equatable, Sendable {
    case deleted
    case deleteFailed
  }

  public struct State {
    public var childName = ""
    public var cloudAccount: CloudSync.Account?
    public var cloudNote: CloudNote?
    public var cloudSync = false
    public var isConfirmingCloudDelete = false
    public var journey = Journey()
    public var profile = Profile()
    public var soundOn = true
    public var speechLogOn = false
    public var speechLogLines = 0
    public var speechLogFile: URL?
    public var strictness: WordMatcher.Strictness = .gentle
    public var voices: [Voice] = []
    public var plusStatus = PlusStatus.free
    public var foundNothingToRestore = false
    public var isManagingSubscription = false
    public var isRequestingRefund = false
    public var gatedRequest: GatedRequest?
    public var gate: ParentGate.State?
    public var grownUp: GrownUpPaywall.State?

    public init() {}

    public var readingFriends: [Friend] {
      Friend.allCases.filter { journey.met.contains($0) || Friend.starters.contains($0) }
    }

    public var voiceName: String {
      guard let id = profile.voiceID, let voice = voices.first(where: { $0.id == id }) else {
        return "Automatic"
      }
      return voice.name
    }
  }

  public enum Action {
    case accentPicked(Profile.Accent)
    case cloud(Cloud)
    case debugResetJourneyTapped
    case debugUnlockEverythingTapped
    case doneTapped
    case friendPicked(Friend)
    case gate(ParentGate.Action)
    case grownUp(GrownUpPaywall.Action)
    case hearVoiceTapped
    case nameChanged(String)
    case nameSubmitted
    case resetOnboardingTapped
    case soundButtonsToggled(Bool)
    case soundToggled(Bool)
    case speechLogCleared
    case speechLogToggled(Bool)
    case strictnessPicked(WordMatcher.Strictness)
    case subscription(Subscription)
    case themePicked(Profile.Theme)
    case voicePicked(String?)
  }

  @Dependency(CloudSync.self) var cloudSync
  @Dependency(ProfileStore.self) var profileStore
  @Dependency(ProgressStore.self) var progressStore
  @Dependency(PurchasesClient.self) var purchases
  @Dependency(GateSeed.self) var gateSeed
  @Dependency(SoundPreference.self) var soundPreference
  @Dependency(SpeechClient.self) var speechClient
  @Dependency(SpeechLog.self) var speechLog
  @Dependency(StrictnessPreference.self) var strictnessPreference

  private func saveJourney(_ journey: Journey) {
    var progress = progressStore.load()
    progress.journey = journey
    progressStore.save(progress)
  }

  private func refreshSpeechLog(_ state: inout State) {
    let entries = speechLog.entries()
    state.speechLogOn = speechLog.isEnabled()
    state.speechLogLines = entries.count
    guard !entries.isEmpty else {
      state.speechLogFile = nil
      return
    }
    let url = URL.temporaryDirectory.appending(path: "hop-tales-speech-log.csv")
    try? SpeechLog.csv(entries).write(to: url, atomically: true, encoding: .utf8)
    state.speechLogFile = url
  }

  private func cloud(_ action: Cloud, _ state: inout State) {
    switch action {
    case let .accountResolved(account):
      state.cloudAccount = account
    case let .copyDeleted(succeeded):
      state.cloudNote = succeeded ? .deleted : .deleteFailed
      if succeeded { state.cloudSync = false }
    case .deleteConfirmed:
      store.addTask {
        let succeeded = (try? await cloudSync.deleteCloudCopy()) != nil
        try store.send(.cloud(.copyDeleted(succeeded)))
      }
    case .deleteTapped:
      state.isConfirmingCloudDelete = true
    case let .toggled(isOn):
      state.cloudSync = isOn
      state.cloudNote = nil
      store.addTask { await cloudSync.setEnabled(isOn) }
      if isOn { checkCloudAccount() }
    }
  }

  private func checkCloudAccount() {
    store.addTask {
      let account = await cloudSync.account()
      try store.send(.cloud(.accountResolved(account)))
    }
  }

  func restore() {
    store.addTask {
      let isPlus = (try? await purchases.restore()) ?? false
      try store.send(.subscription(.restored(isPlus)))
    }
  }

  func reloadStatus() {
    store.addTask {
      let status = await Settings.currentStatus(purchases)
      try store.send(.subscription(.statusResolved(status)))
    }
  }

  func watchStatus() {
    store.addTask {
      var shown = PlusStatus.free
      for await isPlus in purchases.isPlus() {
        let status = PlusStatus.resolved(isPlus: isPlus, details: await purchases.status())
        guard status != shown else { continue }
        shown = status
        try store.send(.subscription(.statusResolved(status)))
      }
    }
  }

  private func save(_ state: State) {
    var saved = state.profile
    saved.childName = state.childName.trimmingCharacters(in: .whitespacesAndNewlines)
    profileStore.save(saved)
  }

  public var body: some Feature {
    Update { state, action in
      switch action {
      case let .accentPicked(accent):
        state.profile.accent = accent
        save(state)

      case let .cloud(action):
        cloud(action, &state)

      case .doneTapped, .nameSubmitted:
        save(state)

      case .gate(.passed):
        grant(&state)

      case .gate(.closeTapped):
        state.gate = nil
        state.gatedRequest = nil

      case .grownUp(.gate(.closeTapped)), .grownUp(.paywall(.closeTapped)),
        .grownUp(.paywall(.subscribed)), .grownUp(.paywall(.tryLevelOneTapped)):
        state.grownUp = nil

      case .gate, .grownUp:
        break

      case let .subscription(action):
        subscription(action, &state)

      case let .friendPicked(friend):
        state.journey.grownUpMoves(to: friend)
        saveJourney(state.journey)

      case .debugResetJourneyTapped:
        state.journey = Journey(starting: state.profile.startingFriend)
        var progress = progressStore.load()
        progress.journey = state.journey
        progress.baskets = [:]
        progressStore.save(progress)

      case .debugUnlockEverythingTapped:
        state.journey = .everything
        var progress = progressStore.load()
        progress.journey = state.journey
        for friend in Friend.allCases {
          let items = WardrobeLibrary.items(for: friend).count
          progress.baskets[friend, default: Basket()].filled = items
        }
        progressStore.save(progress)

      case .resetOnboardingTapped:
        break

      case .hearVoiceTapped:
        let voice = state.profile.voiceID
        let locale = state.profile.accent.locale
        store.addTask { await speechClient.speak(Settings.sample, voice, locale) }

      case let .nameChanged(name):
        state.childName = String(name.prefix(24))

      case let .soundButtonsToggled(isOn):
        state.profile.soundButtons = isOn
        save(state)

      case let .soundToggled(isOn):
        state.soundOn = isOn
        soundPreference.save(isOn)

      case .speechLogCleared:
        speechLog.clear()
        refreshSpeechLog(&state)

      case let .speechLogToggled(isOn):
        speechLog.setEnabled(isOn)
        refreshSpeechLog(&state)

      case let .themePicked(theme):
        state.profile.theme = theme
        save(state)

      case let .strictnessPicked(strictness):
        state.strictness = strictness
        strictnessPreference.save(strictness)

      case let .voicePicked(id):
        state.profile.voiceID = id
        save(state)
        let locale = state.profile.accent.locale
        store.addTask { await speechClient.speak(Settings.sample, id, locale) }
      }
    }
    .onMount { state in
      state.profile = profileStore.load() ?? Profile()
      state.childName = state.profile.childName
      state.journey = progressStore.load().journey
      state.soundOn = soundPreference.load()
      state.strictness = strictnessPreference.load()
      state.voices = speechClient.voices()
      refreshSpeechLog(&state)
      state.cloudSync = cloudSync.isEnabled()
      if state.cloudSync { checkCloudAccount() }
      watchStatus()
    }
    .ifLet(\.gate) {
      ParentGate()
    }
    .ifLet(\.grownUp) {
      GrownUpPaywall()
    }
  }
}

public struct SettingsScreen: View {
  let store: StoreOf<Settings>

  public init(store: StoreOf<Settings>) {
    self.store = store
  }

  public var body: some View {
    Group {
      if let grownUp = store.scope(\.grownUp) {
        GrownUpPaywallScreen(store: grownUp)
      } else if let gate = store.scope(\.gate) {
        ParentGateScreen(store: gate)
      } else {
        settings
      }
    }
    .subscriptionSheets(store)
  }

  private var settings: some View {
    VStack(spacing: 0) {
      SettingsHeader { store.send(.doneTapped) }
      ScrollView {
        VStack(alignment: .leading, spacing: 28) {
          SettingsSection("Hop Tales Plus") { PlusRow(store: store) }
          SettingsSection("Reader") { NameField(store: store) }
          SettingsSection("Reading with") { FriendChoices(store: store) }
          SettingsSection("Accent") { AccentChoices(store: store) }
          SettingsSection("Theme") { ThemeChoices(store: store) }
          SettingsSection("Listening") { StrictnessChoices(store: store) }
          SettingsSection("Sound buttons") { SoundButtonsRow(store: store) }
          SettingsSection("Help voice") { VoiceRow(store: store) }
          SettingsSection("Sounds") { SoundRow(store: store) }
          SettingsSection("iCloud") { CloudRow(store: store) }
          SettingsSection("Speech log") { SpeechLogRow(store: store) }
          SettingsSection("Testing") { TestingButtons(store: store) }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 30)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
      }
      .scrollBounceBehavior(.basedOnSize)
      .scrollDismissesKeyboard(.interactively)
    }
    .background(Paper.page.ignoresSafeArea())
  }
}

struct NameField: View {
  let store: StoreOf<Settings>
  @FocusState private var focused: Bool

  var body: some View {
    TextField(
      "Name or nickname",
      text: Binding(get: { store.childName }, set: { store.send(.nameChanged($0)) })
    )
    .font(Typography.display(22))
    .foregroundStyle(Paper.ink)
    .textContentType(.nickname)
    .autocorrectionDisabled()
    .submitLabel(.done)
    .focused($focused)
    .onSubmit { store.send(.nameSubmitted) }
    .onChange(of: focused) { _, isFocused in
      if !isFocused { store.send(.nameSubmitted) }
    }
    .padding(.horizontal, 16)
    .frame(height: 56)
    .settingsField()
    .contentShape(.rect(cornerRadius: 18))
    .onTapGesture { focused = true }
  }
}

struct FriendChoices: View {
  let store: StoreOf<Settings>

  var body: some View {
    ForEach(store.readingFriends, id: \.self) { friend in
      Button { store.send(.friendPicked(friend)) } label: {
        HStack(spacing: 14) {
          FriendSticker(friend, height: 52)
            .frame(width: 56)
          VStack(alignment: .leading, spacing: 2) {
            Text(friend.name)
              .font(Typography.display(19))
              .foregroundStyle(Paper.ink)
            Text("\(friend.stage) · \(friend.examples.joined(separator: ", "))")
              .font(Typography.ui(14))
              .foregroundStyle(Paper.muted)
          }
        }
        .paperChoice(isSelected: friend == store.journey.activeFriend)
      }
      .buttonStyle(.plain)
      .accessibilityAddTraits(friend == store.journey.activeFriend ? .isSelected : [])
    }
    Text(Phonics.standard)
      .font(Typography.ui(13))
      .foregroundStyle(Paper.muted)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 4)
  }
}
