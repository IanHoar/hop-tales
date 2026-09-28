import ComposableArchitecture2
import Content
import Testing

@testable import Reading

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct ReadingNoiseTests {
  static var quiet: Reading.State {
    var state = Reading.State(story: StoryLibrary.all[0])
    state.isActive = false
    return state
  }

  @Test func aNoisyRoomThatDrownsTheWordsShowsTheCueUntilItQuietens() async {
    let store = TestStore(initialState: Self.quiet) { Reading() }
    store.send(.speechResult(tokens: ["sounds"], isFinal: false))
    for _ in 1..<Reading.noisyAfterTicks { store.send(.noiseLevel(-30)) }
    store.send(.noiseLevel(-30)) { $0.isNoisy = true }
    store.send(.noiseLevel(-45))
    store.send(.noiseLevel(-60)) { $0.isNoisy = false }
    await store.dismount()
  }

  @Test func loudReadingThatIsHeardNeverShowsTheCue() async {
    let store = TestStore(initialState: Self.quiet) { Reading() }
    for _ in 0..<Reading.noisyAfterTicks * 2 { store.send(.noiseLevel(-30)) }
    await store.dismount()
  }

  @Test func aMatchedWordClearsTheCue() async {
    let store = TestStore(initialState: Self.quiet) { Reading() }
    store.send(.speechResult(tokens: ["sounds"], isFinal: false))
    for _ in 1..<Reading.noisyAfterTicks { store.send(.noiseLevel(-30)) }
    store.send(.noiseLevel(-30)) { $0.isNoisy = true }
    store.send(.speechResult(tokens: ["bob"], isFinal: false))
    store.send(.speechResult(tokens: ["bob"], isFinal: false)) {
      $0.isNoisy = false
      $0.recognised = Reading.State.Recognised(
        count: 1, sentenceIndex: 0, stars: 1, wordIndex: 0
      )
      $0.stars = 1
      $0.wordIndex = 1
    }
    for _ in 1..<Reading.noisyAfterTicks { store.send(.noiseLevel(-30)) }
    await store.dismount()
  }

  @Test func theHelpVoiceDoesNotCountAsNoise() async {
    let store = TestStore(initialState: Self.quiet) { Reading() }
    store.send(.speechResult(tokens: ["sounds"], isFinal: false))
    store.send(.currentWordTapped) {
      $0.isSpeaking = true
      $0.usedHelp = true
    }
    for _ in 0..<Reading.noisyAfterTicks * 2 { store.send(.noiseLevel(-30)) }
    await store.dismount()
  }
}
