import ComposableArchitecture2
import Content
import Dependencies
import DesignSystem
import SpeechRecognition
import SwiftUI
import World

@Feature public struct Reading {
  public init() {}

  public struct State: Identifiable {
    public var heardToken: String?
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
    case currentWordTapped
    case helpOffered
    case speechResult(tokens: [String], isFinal: Bool)
  }

  @FeatureState var debouncer = PartialDebouncer()
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
        state.heardToken = match.token
        state.advance(by: match.target == .next ? 2 : 1)

        if state.sentenceIndex != sentenceBefore { debouncer.reset() }
      }
    }

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
    if sentenceIndex >= story.sentences.count { stars += 20 }
  }
}

extension Array {
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}

public struct ReadingScreen: View {
  let store: StoreOf<Reading>

  public init(store: StoreOf<Reading>) {
    self.store = store
  }

  public var body: some View {
    GeometryReader { proxy in
      let geometry = ReadingGeometry(size: proxy.size)

      ZStack {
        Color(hex: 0x8FCB6B)
          .ignoresSafeArea()

        WordCard(
          words: store.sentence?.words ?? [],
          currentIndex: store.wordIndex,
          geometry: geometry
        )
        .position(geometry.cardCenter)
        .onTapGesture { store.send(.currentWordTapped) }

        micPill(geometry)
          .position(x: proxy.size.width / 2, y: geometry.y(762))
      }
    }
    .navigationTitle(store.story.title)
    .navigationBarTitleDisplayMode(.inline)
  }

  private func micPill(_ geometry: ReadingGeometry) -> some View {
    Label(
      store.heardToken.map { "Heard it — “\($0)”" } ?? "Say the word",
      systemImage: store.heardToken == nil ? "mic.fill" : "checkmark"
    )
    .font(Typography.ui(geometry.scaled(15)))
    .foregroundStyle(store.heardToken == nil ? Palette.chipText : Palette.heardText)
    .padding(.horizontal, geometry.scaled(18))
    .padding(.vertical, geometry.scaled(12))
    .background(store.heardToken == nil ? Palette.cream : Palette.heardBg, in: .capsule)
    .shadow(color: Palette.ink.opacity(0.12), radius: 0, x: 0, y: geometry.scaled(4))
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
