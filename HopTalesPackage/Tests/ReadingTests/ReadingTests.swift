import ComposableArchitecture2
import Content
import Dependencies
import SpeechRecognition
import Testing

@testable import Reading
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct ReadingTests {
  @Test func readingAWordAdvancesTheBallAndAwardsAStar() async {
    let store = TestStore(initialState: Reading.State(story: StoryLibrary.all[0])) {
      Reading()
    }

    await store.receive(\.authorizationResolved) {
      $0.authorization = .authorized
    }
    await store.send(.speechResult(tokens: ["the"], isFinal: false)) {
      $0.hearing = ["the"]
    }
    await store.send(.speechResult(tokens: ["the"], isFinal: false)) {
      $0.heardToken = "the"
      $0.recognised = Reading.State.Recognised(
        count: 1,
        sentenceIndex: 0,
        stars: 1,
        wordIndex: 0
      )
      $0.stars = 1
      $0.wordIndex = 1
    }

    await store.dismount()
  }

  @Test func theLastWordOfASentenceCarriesTheBonusIntoTheChip() {
    var state = Reading.State(story: StoryLibrary.all[0])
    let words = state.sentence!.words.count
    state.advance(by: words - 1)
    let before = state.stars
    state.advance(by: 1)
    #expect(state.stars - before == 6)
  }

  @Test func finishingASentenceWithNoHelpAwardsFiveMoreStars() {
    var state = Reading.State(story: StoryLibrary.all[0])
    let words = state.sentence!.words.count
    state.advance(by: words)
    #expect(state.sentenceIndex == 1)
    #expect(state.wordIndex == 0)
    #expect(state.stars == words + 5)
  }

  @Test func theAppDoesNotHearItselfSpeak() async {
    let store = TestStore(initialState: Reading.State(story: StoryLibrary.all[0])) {
      Reading()
    }

    await store.receive(\.authorizationResolved) {
      $0.authorization = .authorized
    }
    await store.send(.currentWordTapped) {
      $0.isSpeaking = true
      $0.usedHelp = true
    }
    await store.send(.speechResult(tokens: ["the"], isFinal: true))
    await store.send(.speechResult(tokens: ["the"], isFinal: true))
    await store.send(.speechFinished) {
      $0.isSpeaking = false
    }

    await store.dismount()
  }

  @Test func askingToHearAWordTwiceOverDoesNotStack() async {
    let store = TestStore(initialState: Reading.State(story: StoryLibrary.all[0])) {
      Reading()
    }

    await store.receive(\.authorizationResolved) {
      $0.authorization = .authorized
    }
    await store.send(.currentWordTapped) {
      $0.isSpeaking = true
      $0.usedHelp = true
    }
    await store.send(.currentWordTapped)
    await store.send(.speechFinished) {
      $0.isSpeaking = false
    }

    await store.dismount()
  }

  @Test func finishingASentenceRecordsWhichOne() {
    var state = Reading.State(story: StoryLibrary.all[0])
    state.advance(by: state.sentence!.words.count)
    #expect(state.completed == .sentence(index: 0))
    #expect(state.completionCount == 1)
  }

  @Test func finishingTheLastSentenceEndsTheStoryInstead() {
    var state = Reading.State(story: StoryLibrary.all[0])
    for sentence in state.story.sentences {
      state.advance(by: sentence.words.count)
    }
    #expect(state.completed == .story(stars: state.stars))
    #expect(state.completionCount == state.story.sentences.count)
  }

  @Test func eachWordReadWalksTheWorldOneStep() {
    var state = Reading.State(story: StoryLibrary.all[0])
    for sentence in state.story.sentences {
      state.advance(by: sentence.words.count)
    }
    #expect(state.worldProgress == Double(state.story.wordCount) * Story.stepPerWord)
  }

  @Test func theWorldMoodFollowsTheSentence() {
    var state = Reading.State(story: StoryLibrary["storm-on-the-hill"]!)
    #expect(state.mood.weather == .clouds)
    state.advance(by: state.sentence!.words.count)
    #expect(state.mood.weather == .storm)
    state.advance(by: state.sentence!.words.count)
    #expect(state.mood.weather == .rain)
  }

  @Test func listeningStartsAgainWhenTheRecogniserStops() async {
    let sessions = LockIsolated(0)
    var speech = SpeechClient.testValue
    speech.listen = { _, _ in
      let session = sessions.withValue { count in
        count += 1
        return count
      }
      return AsyncStream { continuation in
        switch session {
        case 1: continuation.yield(.final(["the"]))
        case 2: continuation.yield(.final(["hare"]))
        default: break
        }
        continuation.finish()
      }
    }
    let store = TestStore(initialState: Reading.State(story: StoryLibrary.all[0])) {
      Reading().dependency(speech)
    }

    await store.receive(\.authorizationResolved) {
      $0.authorization = .authorized
    }
    await store.receive(\.speechResult) {
      $0.hearing = ["the"]
      $0.heardToken = "the"
      $0.recognised = Reading.State.Recognised(
        count: 1,
        sentenceIndex: 0,
        stars: 1,
        wordIndex: 0
      )
      $0.stars = 1
      $0.wordIndex = 1
    }
    await store.receive(\.speechResult, timeout: .seconds(2)) {
      $0.hearing = ["hare"]
      $0.heardToken = "hare"
      $0.recognised = Reading.State.Recognised(
        count: 2,
        sentenceIndex: 0,
        stars: 1,
        wordIndex: 1
      )
      $0.stars = 2
      $0.wordIndex = 2
    }
    #expect(sessions.value >= 2)
    await store.dismount()
  }

  @Test func comingBackFromTheBackgroundListensAfresh() async {
    let sessions = LockIsolated(0)
    var speech = SpeechClient.testValue
    speech.listen = { _, _ in
      sessions.withValue { $0 += 1 }
      return AsyncStream { _ in }
    }
    let store = TestStore(initialState: Reading.State(story: StoryLibrary.all[0])) {
      Reading().dependency(speech)
    }
    await store.receive(\.authorizationResolved) {
      $0.authorization = .authorized
    }
    await store.send(.scenePhaseChanged(isActive: false)) {
      $0.isActive = false
      $0.listeningEpoch = 1
    }
    await store.send(.scenePhaseChanged(isActive: true)) {
      $0.isActive = true
      $0.listeningEpoch = 2
    }
    try? await Task.sleep(for: .milliseconds(200))
    #expect(sessions.value == 2)
    await store.dismount()
  }

  @Test func backAsksBeforeLeavingTheStory() async {
    let store = TestStore(initialState: Reading.State(story: StoryLibrary.all[0])) {
      Reading()
    }

    await store.receive(\.authorizationResolved) {
      $0.authorization = .authorized
    }
    await store.send(.backTapped) {
      $0.isConfirmingStop = true
    }
    await store.send(.keepReadingTapped) {
      $0.isConfirmingStop = false
    }
    await store.send(.backTapped) {
      $0.isConfirmingStop = true
    }
    await store.send(.backToStoriesTapped) {
      $0.isConfirmingStop = false
    }

    await store.dismount()
  }

  @Test(arguments: [true, false])
  func theSentenceChimeFollowsTheSoundSetting(soundOn: Bool) async {
    var state = Reading.State(story: StoryLibrary.all[0])
    state.advance(by: state.sentence!.words.count)
    let chimes = LockIsolated(0)
    let store = TestStore(initialState: state) {
      Reading()
        .dependency(SoundClient(sentenceCompleted: { chimes.withValue { $0 += 1 } }))
        .dependency(SoundPreference(load: { soundOn }, save: { _ in }))
    }

    await store.receive(\.authorizationResolved) {
      $0.authorization = .authorized
    }
    #expect(chimes.value == (soundOn ? 1 : 0))

    await store.dismount()
  }
}
