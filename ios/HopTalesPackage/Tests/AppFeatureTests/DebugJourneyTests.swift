import ComposableArchitecture2
import Content
import Dependencies
import Testing

@testable import GrownUps

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct DebugJourneyTests {
  @Test func unlockingEverythingMeetsEveryFriendAndResettingStartsOver() {
    let saved = LockIsolated(Content.Progress())
    var state = Settings.State()
    state.profile = Profile(startingFriend: .hare)
    let store = TestStore(initialState: state) {
      Settings()
        .dependency(ProgressStore(load: { saved.value }, save: { saved.setValue($0) }))
        .dependency(ProfileStore(load: { Profile(startingFriend: .hare) }, save: { _ in }))
    }

    store.send(.debugUnlockEverythingTapped) {
      $0.journey = .everything
    }
    #expect(saved.value.journey.level == 7)
    #expect(saved.value.journey.met == Set(Friend.allCases))

    store.send(.debugResetJourneyTapped) {
      $0.journey = Journey(starting: .hare)
    }
    #expect(saved.value.journey == Journey(starting: .hare))
  }
}
