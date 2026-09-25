import ComposableArchitecture2
import Content
import Testing

@testable import AppFeature
@testable import Reading
@MainActor
struct RootTests {
  @Test func everyLaunchOpensOnTheIntro() {
    #expect(Root.State().intro != nil)
  }

  @Test func theIntroHandsOverWhenTheHareHasRunOff() async {
    let store = TestStore(initialState: Root.State()) {
      Root()
    }
    store.send(.intro(.started(reduceMotion: true)))
    await store.receive(\.intro.finished, timeout: .seconds(2)) { $0.intro = nil }
  }

  @Test func tappingSkipsTheIntro() async {
    let store = TestStore(initialState: Root.State()) {
      Root()
    }
    store.send(.intro(.started(reduceMotion: false)))
    store.send(.intro(.skipTapped))
    await store.receive(\.intro.finished) { $0.intro = nil }
  }

  @Test func tappingAStoryPushesTheReadingScreen() async {
    let store = TestStore(initialState: Root.State()) {
      Root()
    }
    let story = StoryLibrary.all[0]
    store.send(.home(.storyTapped(story))) {
      $0.path = [.reading(Reading.State.DebugSnapshot(story: story))]
    }

    await store.receive(\.path) {
      $0.path = [
        .reading(Reading.State.DebugSnapshot(authorization: .authorized, story: story))
      ]
    }

    await store.dismount()
  }

  @Test func theTVWaitsUntilAStoryIsOpen() async {
    let store = TestStore(initialState: Root.State()) {
      Root()
    }
    #expect(store.state.storyOnScreen == nil)

    let story = StoryLibrary.all[1]
    store.send(.home(.storyTapped(story))) {
      $0.path = [.reading(Reading.State.DebugSnapshot(story: story))]
    }
    #expect(store.state.storyOnScreen == story)

    await store.receive(\.path) {
      $0.path = [
        .reading(Reading.State.DebugSnapshot(authorization: .authorized, story: story))
      ]
    }
    await store.dismount()
  }
}
