import ComposableArchitecture
import Content
import Dependencies
import Testing

@testable import AppFeature
@testable import Home
@testable import Onboarding

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct FinishingSetUpTests {
  @Test func finishingSetUpGoesStraightToTheStories() async {
    let saved = LockIsolated<Profile?>(nil)
    var state = Root.State()
    state.intro = nil
    state.home.locksStories = true
    let store = TestStore(initialState: state) {
      Root().dependency(
        ProfileStore(load: { saved.value }, save: { saved.setValue($0) }, erase: {})
      )
    } changes: {
      $0.onboarding = Onboarding.State.DebugSnapshot()
      $0.onboarding?.isWelcoming = true
    }
    store.send(.onboarding(.finished(Profile(childName: "Maya")))) {
      $0.onboarding = nil
      $0.home.childName = "Maya"
    }
    #expect(saved.value?.childName == "Maya")
    #expect(saved.value?.plusOffered == false)
    await store.dismount()
  }
}
