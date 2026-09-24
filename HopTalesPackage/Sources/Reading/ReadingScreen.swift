import ComposableArchitecture2
import Content
import Dependencies
import DesignSystem
import SpeechRecognition
import SwiftUI
import World

@Feature public struct Reading {
  public static let settleAfterSpeaking = Duration.milliseconds(300)
  public static let offerHelpAfter = Duration.seconds(6)
  public static let relistenAfterEnd = Duration.milliseconds(150)
  public static let relistenAfterFailure = Duration.seconds(1)

  public init() {}

  public struct State: Identifiable {
    public struct Recognised: Equatable, Sendable {
      public var count: Int
      public var sentenceIndex: Int
      public var stars: Int
      public var wordIndex: Int
    }

    public enum Completed: Equatable, Sendable {
      case sentence(index: Int)
      case story(stars: Int)
    }

    public var authorization: SpeechClient.Authorization?
    public var completed: Completed?
    public var completionCount = 0
    public var heardToken: String?
    public var hearing: [String] = []
    public var isActive = true
    public var isConfirmingStop = false
    public var listeningEpoch = 0
    public var isSpeaking = false
    public var recognised: Recognised?
    public var sentenceIndex = 0
    public var stars = 0
    public var story: Story
    public var strictness: WordMatcher.Strictness = .gentle
    public var usedHelp = false
    public var wordIndex = 0

    public init(story: Story) {
      self.story = story
    }

    public var currentWord: Word? {
      sentence?.words[safe: wordIndex]
    }

    public var nextWord: Word? {
      sentence?.words[safe: wordIndex + 1]
    }

    public var sentence: Sentence? {
      story.sentences[safe: sentenceIndex]
    }

    public var worldProgress: Double {
      Double(wordsCompleted) * Story.stepPerWord
    }

    public var mood: Mood {
      story.mood(atSentence: min(sentenceIndex, story.sentences.count - 1))
    }

    public var wordsCompleted: Int {
      story.sentences.prefix(sentenceIndex).reduce(0) { $0 + $1.words.count } + wordIndex
    }
  }

  public enum Action {
    case authorizationResolved(SpeechClient.Authorization)
    case backTapped
    case backToStoriesTapped
    case currentWordTapped
    case helpOffered
    case keepReadingTapped
    case speechFinished
    case scenePhaseChanged(isActive: Bool)
    case speechResult(tokens: [String], isFinal: Bool)
  }

  @FeatureState var debouncer = PartialDebouncer()
  @FeatureState var savedStars = 0
  @FeatureState var chimedSentence: Int?
  @FeatureState var profile = Profile()
  @Dependency(ProfileStore.self) var profileStore
  @Dependency(ProgressStore.self) var progressStore
  @Dependency(SoundClient.self) var sound
  @Dependency(SoundPreference.self) var soundPreference
  @Dependency(SpeechClient.self) var speechClient
  @Dependency(StrictnessPreference.self) var strictnessPreference

  private func persist(_ state: State) {
    var progress = progressStore.load()
    progress.stars += state.stars - savedStars
    progress.completedSentences[state.story.id] = max(
      progress.completedSentences[state.story.id] ?? 0,
      state.sentenceIndex
    )
    progress.wordsRead[state.story.id] = max(
      progress.wordsRead[state.story.id] ?? 0,
      state.wordsCompleted
    )
    progressStore.save(progress)
    savedStars = state.stars
  }

  public var body: some Feature {
    Update { state, action in
      switch action {
      case let .authorizationResolved(authorization):
        state.authorization = authorization

      case .backTapped:
        state.isConfirmingStop = true

      case .backToStoriesTapped:
        state.isConfirmingStop = false

      case .keepReadingTapped:
        state.isConfirmingStop = false

      case .currentWordTapped, .helpOffered:
        guard let word = state.currentWord?.text, !state.isSpeaking else { break }
        state.usedHelp = true
        state.isSpeaking = true
        let voice = profile.voiceID
        store.addTask {
          await speechClient.speak(word, voice)
          try? await Task.sleep(for: Reading.settleAfterSpeaking)
          try store.send(.speechFinished)
        }

      case .speechFinished:
        state.isSpeaking = false
        debouncer.reset()

      case let .scenePhaseChanged(isActive):
        guard isActive != state.isActive else { break }
        state.isActive = isActive
        state.listeningEpoch += 1

      case let .speechResult(tokens, isFinal):
        guard !state.isSpeaking else { break }
        state.hearing = Array(tokens.suffix(3))
        let eligible = debouncer.confirm(tokens: tokens, isFinal: isFinal)
        guard
          let current = state.currentWord,
          let match = WordMatcher.match(
            tokens: eligible,
            current: current,
            next: state.nextWord,
            strictness: state.strictness
          )
        else { break }
        let sentenceBefore = state.sentenceIndex
        let starsBefore = state.stars
        state.heardToken = match.token
        let readIndex = state.wordIndex
        state.advance(by: match.target == .next ? 2 : 1)
        state.recognised = Reading.State.Recognised(
          count: (state.recognised?.count ?? 0) + 1,
          sentenceIndex: sentenceBefore,
          stars: state.stars - starsBefore,
          wordIndex: readIndex
        )

        if state.sentenceIndex != sentenceBefore {
          debouncer.reset()
          persist(state)
        }
      }
    }

    .onMount(id: [store.sentenceIndex, store.listeningEpoch]) { state in
      guard state.isActive else { return }
      state.strictness = strictnessPreference.load()
      profile = profileStore.load() ?? Profile()
      let locale = profile.accent.locale
      let completed = state.completionCount > 0 && chimedSentence != state.sentenceIndex
      if completed { chimedSentence = state.sentenceIndex }
      let celebrates = completed && soundPreference.load()
      guard let sentence = state.sentence else {
        if celebrates { store.addTask { await sound.sentenceCompleted() } }
        return
      }
      let contextualStrings = sentence.words.map(\.text)
      let known = state.authorization
      store.addTask {
        if celebrates { await sound.sentenceCompleted() }
        let authorization: SpeechClient.Authorization
        if let known {
          authorization = known
        } else {
          authorization = await speechClient.requestAuthorization(locale)
          try store.send(.authorizationResolved(authorization))
        }
        guard authorization == .authorized else { return }
        var heardAt = ContinuousClock.now
        while !Task.isCancelled {
          guard let events = try? await speechClient.listen(contextualStrings, locale) else {
            try await Task.sleep(for: Reading.relistenAfterFailure)
            continue
          }
          for await event in events {
            switch event {
            case let .partial(tokens):
              heardAt = .now
              try store.send(.speechResult(tokens: tokens, isFinal: false))
            case let .final(tokens):
              heardAt = .now
              try store.send(.speechResult(tokens: tokens, isFinal: true))
            case .silence:
              guard ContinuousClock.now - heardAt >= Reading.offerHelpAfter else { break }
              heardAt = .now
              try store.send(.helpOffered)
            }
          }
          try await Task.sleep(for: Reading.relistenAfterEnd)
        }
      }
    }
  }
}

public struct ReadingScreen: View {
  static let heardHold = Duration.milliseconds(1200)
  static let cardToRail: CGFloat = 26
  static let railToPill: CGFloat = 31
  static let pillToEdge: CGFloat = 12
  static let recognisedHold = Duration.milliseconds(450)
  static let chipHold = Duration.milliseconds(900)

  let store: StoreOf<Reading>

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @Environment(\.scenePhase) private var scenePhase
  @State private var showsHearing = false
  @State private var heldToken: String?
  @State private var flash: Reading.State.Recognised?
  @State private var chip: Reading.State.Recognised?

  public init(store: StoreOf<Reading>) {
    self.store = store
  }

  @ViewBuilder
  private var background: some View {
    #if DEBUG
      // Tapping anywhere off the card reads the current word, so a whole story can be walked
      // through in the simulator where nothing is listening.
      world.modifier(DebugTapToAdvance(store: store))
    #else
      world
    #endif
  }

  private var world: some View {
    MeadowBackdrop(progress: store.worldProgress, mood: store.mood)
  }

  private func card(_ geometry: ReadingGeometry, screenWidth: CGFloat? = nil) -> some View {
    SentenceStrip(
      sentences: store.story.sentences.map(\.words),
      position: HopTarget(sentence: store.sentenceIndex, word: store.wordIndex),
      flash: flash.map { HopTarget(sentence: $0.sentenceIndex, word: $0.wordIndex) },
      isSpeaking: store.isSpeaking,
      geometry: geometry,
      screenWidth: screenWidth
    )
    .contentShape(.rect)
    .onTapGesture { store.send(.currentWordTapped) }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(store.wordCardLabel)
    .accessibilityHint("Double tap to hear the word.")
    .accessibilityAddTraits(.startsMediaSession)
    .accessibilityAction { store.send(.currentWordTapped) }
  }

  private var hearing: String? {
    guard showsHearing, !store.hearing.isEmpty else { return nil }
    return store.hearing.joined(separator: " ")
  }

  private var usesPadLayout: Bool {
    horizontalSizeClass == .regular && verticalSizeClass == .regular
  }

  public var body: some View {
    GeometryReader { proxy in
      if usesPadLayout {
        PadReadingLayout(
          store: store,
          size: proxy.size,
          heldToken: heldToken,
          hearing: hearing,
          chip: chip
        ) {
          background
        } card: {
          card($0, screenWidth: proxy.size.width)
        }
      } else {
        phone(proxy)
      }
    }
    .toolbar(.hidden, for: .navigationBar)
    .modifier(ReadingPanels(store: store))
    .task(id: store.completionCount) {
      guard store.completionCount > 0, case .sentence = store.completed else { return }
      Haptics.sentenceCompleted()
    }
    .task {
      showsHearing = await BuildChannel.isPreRelease()
    }
    .onChange(of: scenePhase) { _, phase in
      store.send(.scenePhaseChanged(isActive: phase != .background))
    }
    .task(id: store.recognised) {
      guard let recognised = store.recognised else { return }
      flash = recognised
      chip = recognised
      Haptics.wordRecognised()
      try? await Task.sleep(for: Self.recognisedHold)
      if !Task.isCancelled { flash = nil }
      try? await Task.sleep(for: Self.chipHold)
      if !Task.isCancelled { chip = nil }
    }
    .task(id: store.heardToken) {
      guard let token = store.heardToken else {
        heldToken = nil
        return
      }
      heldToken = token
      try? await Task.sleep(for: Self.heardHold)
      guard !Task.isCancelled else { return }
      heldToken = nil
    }
  }

  private func phone(_ proxy: GeometryProxy) -> some View {
    let geometry = ReadingGeometry(size: proxy.size)
    return ZStack {
      background
        .ignoresSafeArea()

      VStack(spacing: 0) {
        Spacer(minLength: 0)
        card(geometry)
        ProgressRail(
          story: store.story,
          sentenceIndex: store.sentenceIndex,
          geometry: geometry
        )
        .padding(.top, geometry.scaled(Self.cardToRail))
        MicPill(heardToken: heldToken, hearing: hearing, geometry: geometry)
          .padding(.top, geometry.scaled(Self.railToPill))
      }
      .padding(.bottom, geometry.scaled(Self.pillToEdge))
      .frame(width: proxy.size.width, height: proxy.size.height)

      VStack(spacing: 0) {
        ReadingTopBar(title: store.story.title, stars: store.stars, geometry: geometry) {
          store.send(.backTapped)
        }
        .padding(.top, geometry.scaled(6))
        Spacer()
      }

      if let chip {
        StarChip(stars: chip.stars, geometry: geometry)
          .id(chip.count)
          .position(x: proxy.size.width - geometry.scaled(58), y: geometry.scaled(96))
      }

      #if DEBUG
        DebugControls(store: store)
          .position(x: proxy.size.width / 2, y: geometry.scaled(150))
      #endif
    }
  }
}
