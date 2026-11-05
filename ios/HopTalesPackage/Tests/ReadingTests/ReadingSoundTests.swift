import ComposableArchitecture
import Content
import Dependencies
import DependenciesTestSupport
import SpeechRecognition
import Testing

@testable import Reading
@MainActor
@Suite(.steady, .timeLimit(.minutes(1)))
struct ReadingSoundTests {
  @Test(arguments: [true, false])
  func theSentenceChimeFollowsTheSoundSetting(soundOn: Bool) async {
    let state = Reading.State(story: StoryLibrary.all[0])
    let chimes = LockIsolated(0)
    let store = TestStore(initialState: state) {
      Reading()
        .dependency(SoundClient(sentenceCompleted: { chimes.withValue { $0 += 1 } }))
        .dependency(SoundPreference(load: { soundOn }, save: { _ in }))
    }

    await store.receive(\.authorizationResolved) {
      $0.authorization = .authorized
    }
    await store.modify { $0.completionCount += 1 } changes: {
      $0.completionCount = 1
    }?.value
    #expect(chimes.value == (soundOn ? 1 : 0))

    await store.dismount()
  }
}
