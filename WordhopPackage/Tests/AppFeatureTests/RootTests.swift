import ComposableArchitecture2
import Content
import Testing

@testable import AppFeature

struct RootTests {
  @Test func tappingAStoryPushesTheReadingScreen() async {
    let store = await TestStoreActor(initialState: Root.State()) {
      Root()
    }
    let story = StoryLibrary.all[0]
    await store.send(.home(.storyTapped(story))) {
      $0.path = [.reading(Reading.State(story: story))]
    }
  }
}
