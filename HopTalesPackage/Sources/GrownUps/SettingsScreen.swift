import ComposableArchitecture2
import Content
import Dependencies
import DesignSystem
import SpeechRecognition
import SwiftUI
import World

@Feature public struct Settings {
  public static let sample = "Let's read together!"

  public init() {}

  public struct State {
    public var childName = ""
    public var journey = Journey()
    public var profile = Profile()
    public var soundOn = true
    public var speechLogOn = false
    public var speechLogLines = 0
    public var speechLogFile: URL?
    public var strictness: WordMatcher.Strictness = .gentle
    public var voices: [Voice] = []

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
    case debugResetJourneyTapped
    case debugUnlockEverythingTapped
    case doneTapped
    case friendPicked(Friend)
    case hearVoiceTapped
    case nameChanged(String)
    case nameSubmitted
    case resetOnboardingTapped
    case soundButtonsToggled(Bool)
    case soundToggled(Bool)
    case speechLogCleared
    case speechLogToggled(Bool)
    case strictnessPicked(WordMatcher.Strictness)
    case themePicked(Profile.Theme)
    case voicePicked(String?)
  }

  @Dependency(ProfileStore.self) var profileStore
  @Dependency(ProgressStore.self) var progressStore
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

      case .doneTapped, .nameSubmitted:
        save(state)

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
        store.addTask { await speechClient.speak(Settings.sample, voice) }

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
        store.addTask { await speechClient.speak(Settings.sample, id) }
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
    }
  }
}

extension WordMatcher.Strictness {
  var title: String {
    switch self {
    case .gentle: "Gentle"
    case .standard: "Standard"
    }
  }

  var detail: String {
    switch self {
    case .gentle:
      "Accepts close tries, dropped endings and sound-alikes. Best for new readers."
    case .standard:
      "Wants each word said clearly. A small slip is still fine."
    }
  }
}

public struct SettingsScreen: View {
  let store: StoreOf<Settings>

  public init(store: StoreOf<Settings>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      SettingsHeader { store.send(.doneTapped) }
      ScrollView {
        VStack(alignment: .leading, spacing: 28) {
          SettingsSection("Reader") { NameField(store: store) }
          SettingsSection("Reading with") { FriendChoices(store: store) }
          SettingsSection("Accent") { AccentChoices(store: store) }
          SettingsSection("Theme") { ThemeChoices(store: store) }
          SettingsSection("Listening") { StrictnessChoices(store: store) }
          SettingsSection("Sound buttons") { SoundButtonsRow(store: store) }
          SettingsSection("Help voice") { VoiceRow(store: store) }
          SettingsSection("Sounds") { SoundRow(store: store) }
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

struct SettingsSection<Content: View>: View {
  let title: String
  let content: Content

  init(_ title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title.uppercased())
        .font(Typography.ui(13, weight: .semibold))
        .tracking(13 * 0.14)
        .foregroundStyle(Paper.muted)
        .padding(.horizontal, 4)
        .accessibilityAddTraits(.isHeader)
      content
    }
  }
}

extension View {
  func settingsField() -> some View {
    let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
    return background(Paper.rim.opacity(0.6), in: shape)
      .overlay(shape.strokeBorder(Paper.rim, lineWidth: 3))
      .shadow(color: Paper.shadow.opacity(0.5), radius: 3, y: 2)
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

struct VoiceRow: View {
  let store: StoreOf<Settings>

  var body: some View {
    HStack(spacing: 12) {
      Menu {
        Picker(
          "Help voice",
          selection: Binding(get: { store.profile.voiceID }, set: { store.send(.voicePicked($0)) })
        ) {
          Text("Automatic").tag(String?.none)
          ForEach(store.voices) { voice in
            Text("\(voice.name) · \(voice.region)").tag(Optional(voice.id))
          }
        }
      } label: {
        HStack {
          Text(store.voiceName)
            .font(Typography.display(19))
            .foregroundStyle(Paper.ink)
          Spacer(minLength: 0)
          Image(systemName: "chevron.up.chevron.down")
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(Paper.muted)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .settingsField()
        .contentShape(.rect(cornerRadius: 18))
      }
      .accessibilityLabel("Help voice, \(store.voiceName)")
      Button { store.send(.hearVoiceTapped) } label: {
        Image(systemName: "speaker.wave.2.fill")
          .font(.system(size: 18, weight: .bold))
          .foregroundStyle(Paper.ink)
          .frame(width: 56, height: 56)
          .paperChip(Circle(), rim: 3)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Hear the help voice")
    }
  }
}
