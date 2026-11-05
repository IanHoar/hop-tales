import ComposableArchitecture
import ConcurrencyExtras
import Content
import Dependencies
import DependenciesTestSupport
import Foundation
import SpeechRecognition
import Testing

@testable import Reading
@MainActor
@Suite(.steady, .timeLimit(.minutes(1)))
struct ReadingHintTests {
  @Test func silenceOffersAHintWithoutSpeaking() async {
    let store = TestStore(initialState: Reading.State(story: StoryLibrary.all[0])) {
      Reading()
    }

    await store.receive(\.authorizationResolved) {
      $0.authorization = .authorized
    }
    store.send(.hintOffered) {
      $0.isOfferingHint = true
    }
    store.send(.hintTapped) {
      $0.isOfferingHint = false
      $0.isSpeaking = true
      $0.usedHelp = true
    }
    store.send(.speechFinished) {
      $0.isSpeaking = false
    }

    await store.dismount()
  }

  @Test func onlyALongSilenceOffersAHint() async {
    let now = LockIsolated(Date(timeIntervalSince1970: 0))
    let (events, hear) = AsyncStream.makeStream(of: SpeechClient.Event.self)
    var speech = SpeechClient.testValue
    speech.listen = { _, _ in events }
    let store = withDependencies {
      $0.date = DateGenerator { now.value }
    } operation: {
      TestStore(initialState: Reading.State(story: StoryLibrary.all[0])) {
        Reading().dependency(speech)
      }
    }
    await store.receive(\.authorizationResolved) {
      $0.authorization = .authorized
    }

    now.setValue(Date(timeIntervalSince1970: 3))
    hear.yield(.silence(3))
    now.setValue(Date(timeIntervalSince1970: 7))
    hear.yield(.silence(7))
    await store.receive(\.hintOffered) {
      $0.isOfferingHint = true
    }

    hear.finish()
    await store.dismount()
  }

  @Test func readingTheWordPutsTheHintAway() async {
    let store = TestStore(initialState: Reading.State(story: StoryLibrary.all[0])) {
      Reading()
    }

    await store.receive(\.authorizationResolved) {
      $0.authorization = .authorized
    }
    store.send(.hintOffered) {
      $0.isOfferingHint = true
    }
    await store.send(.speechResult(tokens: ["bob"], isFinal: false))
    await store.send(.speechResult(tokens: ["bob"], isFinal: false)) {
      $0.isOfferingHint = false
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
}
