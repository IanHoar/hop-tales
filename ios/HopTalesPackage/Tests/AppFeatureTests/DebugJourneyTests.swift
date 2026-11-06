import ComposableArchitecture
import Content
import Dependencies
import DependenciesTestSupport
import Testing

@testable import GrownUps

@MainActor
@Suite(.steady, .timeLimit(.minutes(1)))
struct DebugJourneyTests {
  @Test func unlockingEverythingMeetsEveryFriendAndResettingStartsOver() async {
    let saved = LockIsolated(
      Content.Progress(completedSentences: ["bob-bug": 6], wordsRead: ["bob-bug": 24])
    )
    var state = Settings.State()
    state.profile = Profile(startingFriend: .hare)
    let store = TestStore(initialState: state) {
      Settings()
        .dependency(ProgressStore(load: { saved.value }, save: { saved.setValue($0) }))
        .dependency(ProfileStore(load: { Profile(startingFriend: .hare) }, save: { _ in }))
    }

    store.send(.debugUnlockEverythingTapped)
    #expect(saved.value.journey.level == 7)
    #expect(saved.value.journey.met == Set(Friend.allCases))

    store.send(.debugResetJourneyTapped)
    #expect(saved.value.journey == Journey(starting: .hare))
    #expect(saved.value.completedSentences.isEmpty)
    #expect(saved.value.wordsRead.isEmpty)
    await store.dismount()
  }
}
