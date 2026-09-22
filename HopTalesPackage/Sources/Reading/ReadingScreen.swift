import ComposableArchitecture2
import Content
import Dependencies
import DesignSystem
import SpeechRecognition
import SwiftUI
import World

@Feature public struct Reading {
  public static let settleAfterSpeaking = Duration.milliseconds(300)

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
      Double(wordsCompleted) * story.wordStep
    }

    public var wordsCompleted: Int {
      story.sentences.prefix(sentenceIndex).reduce(0) { $0 + $1.words.count } + wordIndex
    }
  }

  public enum Action {
    case authorizationResolved(SpeechClient.Authorization)
    case backToStoriesTapped
    case currentWordTapped
    case helpOffered
    case speechFinished
    case speechResult(tokens: [String], isFinal: Bool)
  }

  @FeatureState var debouncer = PartialDebouncer()
  @FeatureState var savedStars = 0
  @Dependency(ProgressStore.self) var progressStore
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

      case .backToStoriesTapped:
        break

      case .currentWordTapped, .helpOffered:
        guard let word = state.currentWord?.text, !state.isSpeaking else { break }
        state.usedHelp = true
        state.isSpeaking = true
        store.addTask {
          await speechClient.speak(word)
          try? await Task.sleep(for: Reading.settleAfterSpeaking)
          try store.send(.speechFinished)
        }

      case .speechFinished:
        state.isSpeaking = false
        debouncer.reset()

      case let .speechResult(tokens, isFinal):
        guard !state.isSpeaking else { break }
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

    .onMount(id: store.sentenceIndex) { state in
      state.strictness = strictnessPreference.load()
      guard let sentence = state.sentence else { return }
      let contextualStrings = sentence.words.map(\.text)
      let known = state.authorization
      store.addTask {
        let authorization: SpeechClient.Authorization
        if let known {
          authorization = known
        } else {
          authorization = await speechClient.requestAuthorization()
          try store.send(.authorizationResolved(authorization))
        }
        guard authorization == .authorized else { return }
        let events = try await speechClient.listen(contextualStrings)
        for await event in events {
          switch event {
          case let .partial(tokens):
            try store.send(.speechResult(tokens: tokens, isFinal: false))
          case let .final(tokens):
            try store.send(.speechResult(tokens: tokens, isFinal: true))
          case .silence(let seconds) where seconds >= 6:
            try store.send(.helpOffered)
          case .silence:
            break
          }
        }
      }
    }
  }
}

extension Reading.State {
  mutating func advance(by count: Int) {
    guard let sentence else { return }
    let read = min(count, sentence.words.count - wordIndex)
    guard read > 0 else { return }

    stars += read
    wordIndex += read

    guard wordIndex >= sentence.words.count else { return }
    if !usedHelp { stars += 5 }
    let finished = sentenceIndex
    sentenceIndex += 1
    wordIndex = 0
    usedHelp = false
    completionCount += 1
    if sentenceIndex >= story.sentences.count {
      stars += 20
      completed = .story(stars: stars)
    } else {
      completed = .sentence(index: finished)
    }
  }
}

extension Array {
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
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
      Color(hex: 0x8FCB6B).modifier(DebugTapToAdvance(store: store))
    #else
      Color(hex: 0x8FCB6B)
    #endif
  }

  private func card(_ geometry: ReadingGeometry) -> some View {
    WordCard(
      words: store.sentence?.words ?? [],
      currentIndex: store.wordIndex,
      recognisedIndex: flashIndex,
      completionCount: store.completionCount,
      isSpeaking: store.isSpeaking,
      geometry: geometry
    )
    .id(store.sentenceIndex)
    .transition(.move(edge: .trailing).combined(with: .opacity))
    .animation(Motion.recognised, value: store.sentenceIndex)
    .overlay {
      if flash != nil, !reduceMotion {
        Sparkles(geometry: geometry)
          .accessibilityHidden(true)
      }
    }
    .contentShape(.rect)
    .onTapGesture { store.send(.currentWordTapped) }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(wordCardLabel)
    .accessibilityHint("Double tap to hear the word.")
    .accessibilityAddTraits(.startsMediaSession)
    .accessibilityAction { store.send(.currentWordTapped) }
  }

  private var wordCardLabel: String {
    guard let word = store.currentWord?.text else { return "Reading" }
    return "Current word: \(word). Say it out loud."
  }

  private var flashIndex: Int? {
    guard let flash, flash.sentenceIndex == store.sentenceIndex else { return nil }
    return flash.wordIndex
  }

  public var body: some View {
    GeometryReader { proxy in
      let geometry = ReadingGeometry(size: proxy.size)

      ZStack {
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
          MicPill(heardToken: heldToken, geometry: geometry)
            .padding(.top, geometry.scaled(Self.railToPill))
        }
        .padding(.bottom, geometry.scaled(Self.pillToEdge))
        .frame(width: proxy.size.width, height: proxy.size.height)

        if let chip {
          StarChip(stars: chip.stars, geometry: geometry)
            .id(chip.count)
            .position(x: geometry.scaled(290), y: geometry.y(118))
        }

        #if DEBUG
          DebugControls(store: store)
            .position(x: proxy.size.width / 2, y: geometry.y(70))
        #endif
      }
    }
    .navigationTitle(store.story.title)
    .navigationBarTitleDisplayMode(.inline)
    .overlay {
      if let authorization = store.authorization, authorization != .authorized {
        ListeningUnavailable(authorization: authorization) {
          store.send(.backToStoriesTapped)
        }
        .transition(.opacity)
      }
    }
    .overlay {
      if case let .story(stars) = store.completed {
        StoryFinished(title: store.story.title, stars: stars) {
          store.send(.backToStoriesTapped)
        }
        .transition(.opacity)
      }
    }
    .animation(Motion.recognised, value: store.completed)
    .task(id: store.completionCount) {
      guard store.completionCount > 0, case .sentence = store.completed else { return }
      Haptics.sentenceCompleted()
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
}

#Preview {
  NavigationStack {
    ReadingScreen(
      store: Store(initialState: Reading.State(story: StoryLibrary.all[0])) {
        Reading()
      }
    )
  }
}
