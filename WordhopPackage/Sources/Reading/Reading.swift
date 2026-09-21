import ComposableArchitecture2
import Content
import Dependencies
import SpeechRecognition

/// The reading loop: one big word, a ball on top, a microphone listening for it
/// (`HANDOFF.md` §4–§5).
///
/// Nothing here is timed against the child. Silence is fine — after ~6s the app *offers help*
/// (speaks the word gently); it never fails them and never shows a red X.
@Feature public struct Reading {
  public init() {}

  public struct State: Identifiable {
    public var debouncer = PartialDebouncer()
    /// What the recogniser heard, shown in the mic pill for ~1.2s.
    public var heardToken: String?
    public var sentenceIndex = 0
    public var stars = 0
    public var story: Story
    public var strictness: WordMatcher.Strictness = .gentle
    /// Whether this sentence was read without the app speaking a word aloud (worth +5 stars).
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

    /// World progress in near-layer points.
    public var worldProgress: Double {
      Double(wordsCompleted) * story.wordStep
    }

    public var wordsCompleted: Int {
      story.sentences.prefix(sentenceIndex).reduce(0) { $0 + $1.words.count } + wordIndex
    }
  }

  public enum Action {
    case currentWordTapped
    case helpOffered
    case speechResult(tokens: [String], isFinal: Bool)
  }

  @Dependency(SpeechClient.self) var speechClient

  public var body: some Feature {
    Update { state, action in
      switch action {
      case .currentWordTapped, .helpOffered:
        guard let word = state.currentWord?.text else { break }
        state.usedHelp = true
        store.addTask {
          await speechClient.speak(word)
        }

      case let .speechResult(tokens, isFinal):
        let eligible = state.debouncer.confirm(tokens: tokens, isFinal: isFinal)
        guard
          let current = state.currentWord,
          let match = WordMatcher.match(
            tokens: eligible,
            current: current,
            next: state.nextWord,
            strictness: state.strictness
          )
        else { break }
        state.heardToken = match.token
        state.advance(by: match.target == .next ? 2 : 1)
      }
    }
    // One recognition task per sentence: torn down and restarted between sentences.
    .onMount(id: store.sentenceIndex) { state in
      guard let sentence = state.sentence else { return }
      let contextualStrings = sentence.words.map(\.text)
      store.addTask {
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
  /// Marks `count` words read and moves the ball on. Stars: 1 per word, +5 for a sentence read
  /// with no help, +20 for a finished story.
  mutating func advance(by count: Int) {
    guard let sentence else { return }
    let read = min(count, sentence.words.count - wordIndex)
    guard read > 0 else { return }

    stars += read
    wordIndex += read

    guard wordIndex >= sentence.words.count else { return }
    if !usedHelp { stars += 5 }
    sentenceIndex += 1
    wordIndex = 0
    usedHelp = false
    debouncer.reset()
    if sentenceIndex >= story.sentences.count { stars += 20 }
  }
}

extension Array {
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
