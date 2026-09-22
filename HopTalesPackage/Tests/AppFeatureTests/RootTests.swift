import ComposableArchitecture2
import Content
import Testing

@testable import AppFeature
@testable import Reading
@MainActor
struct RootTests {
  @Test func tappingAStoryPushesTheReadingScreen() async {
    let store = TestStore(initialState: Root.State()) {
      Root()
    }
    let story = StoryLibrary.all[0]
    store.send(.home(.storyTapped(story))) {
      $0.path = [.reading(Reading.State.DebugSnapshot(story: story))]
    }

    await store.dismount()
  }
}
