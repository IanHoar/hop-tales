import ComposableArchitecture
import Content
import Dependencies
import DesignSystem
import SpeechRecognition
import SwiftUI
import World

@Feature public struct Reading {
  public init() {}

  public struct State: Identifiable {
    public var authorization: SpeechClient.Authorization?
    public var bigWords: Set<WordRef> = []
    public var friend = Friend.hare
    public var isPlus = false
    public var locksStories = Plus.locksStories
    public var look: String?
    public var treat: StoryTreat?
    public var completed: Completed?
    public var completionCount = 0
    public var isActive = true
    public var journeyMoments: [JourneyMoment] = []
    public var hasTriedItOn = false
    public var isConfirmingStop = false
    public var isNoisy = false
    public var isOfferingHint = false
    public var listeningEpoch = 0
    public var isSpeaking = false
    public var recognised: Recognised?
    public var soundButtons = false
    public var sentenceIndex = 0
    public var stars = 0
    public var story: Story
    public var strictness: WordMatcher.Strictness = .gentle
    public var usedHelp = false
    public var wordIndex = 0

    public init(
      story: Story, friend: Friend = .hare, bigWords: Set<WordRef> = [], treat: StoryTreat? = nil
    ) {
      self.story = story
      self.friend = friend
      self.bigWords = bigWords
      self.treat = treat
    }
  }

  public enum Action {
    case authorizationResolved(SpeechClient.Authorization)
    case backTapped
    case backToStoriesTapped
    case currentWordTapped
    case backToMyStoriesTapped
    case readAgainTapped
    case hintOffered
    case hintTapped
    case keepReadingTapped
    case calloutPrimaryTapped
    case momentDismissed
    case speechFinished
    case scenePhaseChanged(isActive: Bool)
    case speechResult(tokens: [String], isFinal: Bool)
    case noiseLevel(Double)
  }

  @FeatureState var debouncer = PartialDebouncer()
  @FeatureState var savedStars = 0
  @FeatureState var profile = Profile()
  @FeatureState var wordsHelped: Set<WordRef> = []
  @FeatureState var wordsRead: Set<WordRef> = []
  @FeatureState var noiseLevel: Double?
  @FeatureState var ticksSinceMatch = 0
  @FeatureState var heardSinceMatch = false
  @Dependency(\.continuousClock) var clock
  @Dependency(IdleTimer.self) var idleTimer
  @Dependency(\.date) var date
  @Dependency(ProfileStore.self) var profileStore
  @Dependency(ProgressStore.self) var progressStore
  @Dependency(SoundClient.self) var sound
  @Dependency(SoundPreference.self) var soundPreference
  @Dependency(SpeechClient.self) var speechClient
  @Dependency(StrictnessPreference.self) var strictnessPreference
  @Dependency(SpeechLog.self) var speechLog

  public var body: some Feature {
    Update { state, action in
      switch action {
      case let .authorizationResolved(authorization):
        state.authorization = authorization

      case .backTapped:
        guard case .story = state.completed else {
          state.isConfirmingStop = true
          break
        }
        store.addTask { try store.dismiss() }

      case .readAgainTapped:
        state.sentenceIndex = 0
        state.wordIndex = 0
        state.stars = 0
        state.usedHelp = false
        state.isOfferingHint = false
        state.journeyMoments = []
        wordsHelped = []
        wordsRead = []
        state.completed = nil
        state.recognised = nil
        savedStars = 0
        debouncer.reset()

      case .backToStoriesTapped:
        state.isConfirmingStop = false
        store.addTask { try store.dismiss() }

      case .keepReadingTapped:
        state.isConfirmingStop = false

      case .calloutPrimaryTapped:
        guard let callout = state.callout else { break }
        if case let .basketFull(friend, _) = callout {
          state.hasTriedItOn = true
          store.addTask { try store.post(TryingItOn(friend: friend)) }
        }
        guard callout.story != nil else { break }
        state.dismissCallout()
        guard state.callout == nil else { break }
        store.addTask { try store.dismiss() }

      case .momentDismissed:
        state.hasTriedItOn = false
        state.dismissCallout()

      case .backToMyStoriesTapped:
        state.dismissCallout()
        guard state.callout == nil else { break }
        store.addTask { try store.dismiss() }

      case .hintOffered:
        guard state.currentWord != nil, !state.isSpeaking else { break }
        state.isOfferingHint = true

      case .currentWordTapped, .hintTapped:
        guard let word = state.currentWord?.text, !state.isSpeaking else { break }
        state.isOfferingHint = false
        wordsHelped.insert(WordRef(sentence: state.sentenceIndex, word: state.wordIndex))
        state.usedHelp = true
        state.isSpeaking = true
        let voice = profile.voiceID
        let locale = profile.accent.locale
        store.addTask {
          await speechClient.speak(word, voice, locale)
          try? await clock.sleep(for: Reading.settleAfterSpeaking)
          try store.send(.speechFinished)
        }

      case .speechFinished:
        state.isSpeaking = false
        debouncer.reset()

      case let .scenePhaseChanged(isActive):
        guard isActive != state.isActive else { break }
        state.isActive = isActive
        state.listeningEpoch += 1

      case let .noiseLevel(level):
        hear(level, in: &state)

      case let .speechResult(tokens, isFinal):
        guard !state.isSpeaking else {
          log(tokens, isFinal: isFinal, outcome: .speaking, in: state)
          break
        }
        let eligible = debouncer.confirm(tokens: tokens, isFinal: isFinal)
        let match = state.currentWord.flatMap { current in
          WordMatcher.match(
            tokens: eligible,
            current: current,
            next: state.nextWord,
            strictness: state.strictness
          )
        }
        let outcome: SpeechLogEntry.Outcome = switch match?.target {
        case .current: .current
        case .next: .next
        case nil: eligible.isEmpty ? .waiting : .none
        }
        log(tokens, isFinal: isFinal, outcome: outcome, in: state)
        if match == nil { missed(tokens) }
        guard let match else { break }
        matched(&state)
        state.isOfferingHint = false
        let sentenceBefore = state.sentenceIndex
        let starsBefore = state.stars
        let readIndex = state.wordIndex
        let count = match.target == .next ? 2 : 1
        for offset in 0..<count {
          wordsRead.insert(WordRef(sentence: sentenceBefore, word: readIndex + offset))
        }
        state.advance(by: count)
        state.recognised = Reading.State.Recognised(
          count: (state.recognised?.count ?? 0) + 1,
          sentenceIndex: sentenceBefore,
          stars: state.stars - starsBefore,
          wordIndex: readIndex
        )

        if state.sentenceIndex != sentenceBefore {
          debouncer.reset()
          persist(state)
          if case .story = state.completed { finish(&state) }
        }
      }
    }
    .onMount { _ in
      idleTimer.keepAwake(true)
    }
    .onDismount {
      idleTimer.keepAwake(false)
    }
    .onChange(of: store.completionCount) { before, after, _ in
      guard after > before, soundPreference.load() else { return }
      store.addTask { await sound.sentenceCompleted() }
    }
    .onMount(id: [store.sentenceIndex, store.listeningEpoch]) { state in
      guard state.isActive else { return }
      state.strictness = strictnessPreference.load()
      profile = profileStore.load() ?? Profile()
      state.soundButtons = profile.soundButtons
      let locale = profile.accent.locale
      guard let sentence = state.sentence else { return }
      let contextualStrings = sentence.words.map(\.text)
      let known = state.authorization
      store.addTask {
        let authorization: SpeechClient.Authorization
        if let known {
          authorization = known
        } else {
          authorization = await speechClient.requestAuthorization(locale)
          try store.send(.authorizationResolved(authorization))
        }
        guard authorization == .authorized else { return }
        var heardAt = date.now
        while !Task.isCancelled {
          guard let events = try? await speechClient.listen(contextualStrings, locale) else {
            try await clock.sleep(for: Reading.relistenAfterFailure)
            continue
          }
          for await event in events {
            switch event {
            case let .partial(tokens):
              heardAt = date.now
              try store.send(.speechResult(tokens: tokens, isFinal: false))
            case let .final(tokens):
              heardAt = date.now
              try store.send(.speechResult(tokens: tokens, isFinal: true))
            case .silence:
              guard Self.hasBeenQuiet(since: heardAt, now: date.now) else { break }
              heardAt = date.now
              try store.send(.hintOffered)
            case let .level(level):
              try store.send(.noiseLevel(level))
            }
          }
          try await clock.sleep(for: Reading.relistenAfterEnd)
        }
      }
    }
  }
}

public struct ReadingScreen: View {
  let store: StoreOf<Reading>

  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  @Environment(\.scenePhase) private var scenePhase

  public init(store: StoreOf<Reading>) {
    self.store = store
  }

  private func metrics(for size: CGSize) -> Metrics {
    Metrics.forScreen(
      size, regular: horizontalSizeClass == .regular && verticalSizeClass == .regular
    )
  }

  public var body: some View {
    GeometryReader { outer in
      let metrics = metrics(for: CGSize(
        width: outer.size.width + outer.safeAreaInsets.leading + outer.safeAreaInsets.trailing,
        height: outer.size.height + outer.safeAreaInsets.top + outer.safeAreaInsets.bottom
      ))
      let chrome = ReadingGeometry(metrics: metrics, size: outer.size)
      ZStack(alignment: .topLeading) {
        GeometryReader { proxy in
          PathStage(store: store, geometry: ReadingGeometry(metrics: metrics, size: proxy.size))
        }
        .ignoresSafeArea()
        BackChip(geometry: chrome) { store.send(.backTapped) }
          .padding(.leading, chrome.path(18) - (chrome.path(44) - chrome.path(38)) / 2)
          .padding(.top, chrome.path(4))
        NoiseCueSlot(isNoisy: store.isNoisy, geometry: chrome)
          .padding(.top, chrome.path(4))
        HintChipSlot(isOffering: store.isOfferingHint, geometry: chrome) {
          store.send(.hintTapped)
        }
        .padding(.trailing, chrome.path(18))
        .padding(.top, chrome.path(4))
        #if DEBUG
          if store.currentWord != nil {
            DebugControls(store: store)
              .position(x: outer.size.width / 2, y: outer.size.height - 28)
          }
        #endif
      }
    }
    .toolbar(.hidden, for: .navigationBar)
    .modifier(ReadingPanels(store: store))
    .sensoryFeedback(.success, trigger: store.completionCount) { _, count in
      guard count > 0, case .sentence = store.completed else { return false }
      return true
    }
    .onChange(of: scenePhase) { _, phase in
      store.send(.scenePhaseChanged(isActive: phase != .background))
    }
    .sensoryFeedback(.impact(flexibility: .soft), trigger: store.recognised) { _, word in
      word != nil
    }
  }
}
