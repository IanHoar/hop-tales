import Clocks
import ComposableArchitecture
import Content
import Dependencies
import DependenciesTestSupport
import Testing
import World

@testable import AppFeature
@testable import Home
@testable import Reading
@MainActor
@Suite(.steady, .dependency(\.continuousClock, TestClock()), .timeLimit(.minutes(1)))
struct RootTests {
  @Test func everyLaunchOpensOnTheIntro() {
    #expect(Root.State().intro != nil)
  }

  @Test func theIntroHandsOverWhenTheHareHasRunOff() async {
    let clock = TestClock()
    let store = withDependencies {
      $0.continuousClock = clock
    } operation: {
      TestStore(initialState: Root.State()) {
        Root()
      }
    }
    await clock.advance(by: .seconds(IntroTimeline.route))
    await store.expect { $0.intro = nil }
    await store.dismount()
  }

  @Test func tappingSkipsTheIntro() async {
    let store = withDependencies {
      $0.continuousClock = TestClock()
    } operation: {
      TestStore(initialState: Root.State()) {
        Root()
      }
    }
    await store.send(to: \.intro, .skipTapped) {
      $0.intro = nil
    }?.value
    await store.dismount()
  }

  @Test func tappingAStoryPushesTheReadingScreen() async {
    let store = TestStore(initialState: Root.State()) {
      Root()
    }
    let story = StoryLibrary.all[0]
    let big = Journey().bigWords(in: story)
    let treat = Journey().treat(in: story)
    let friend = story.friend
    store.send(.home(.storyTapped(story))) {
      $0.path = [.reading(Reading.State.DebugSnapshot(
        bigWords: big, friend: friend, look: "bow", treat: treat, story: story
      ))]
    }

    await store.receive(\.path) {
      $0.path = [
        .reading(
          Reading.State.DebugSnapshot(
            authorization: .authorized, bigWords: big, friend: friend, look: "bow", treat: treat,
            story: story
          )
        )
      ]
    }

    await store.dismount()
  }

  @Test func aStoryOpensKnowingWhetherStoriesLockAndThePlan() async {
    var state = Root.State()
    state.home.locksStories = true
    state.home.isPlus = true
    let store = TestStore(initialState: state) {
      Root()
        .dependency(PurchasesClient.fixed(true))
    }
    let story = StoryLibrary.all[0]
    let big = Journey().bigWords(in: story)
    let treat = Journey().treat(in: story)
    let friend = story.friend
    store.send(.home(.storyTapped(story))) {
      $0.path = [.reading(Reading.State.DebugSnapshot(
        bigWords: big, friend: friend, isPlus: true, locksStories: true, look: "bow",
        treat: treat, story: story
      ))]
    }

    await store.receive(\.path) {
      $0.path = [
        .reading(
          Reading.State.DebugSnapshot(
            authorization: .authorized, bigWords: big, friend: friend, isPlus: true,
            locksStories: true, look: "bow", treat: treat, story: story
          )
        )
      ]
    }

    await store.dismount()
  }

  @Test func theTVWaitsUntilAStoryIsOpen() async {
    var state = Root.State()
    state.home.locksStories = false
    let store = TestStore(initialState: state) {
      Root()
    }
    #expect(store.state.storyOnScreen == nil)

    let story = StoryLibrary.all[1]
    let big = Journey().bigWords(in: story)
    let treat = Journey().treat(in: story)
    let friend = story.friend
    store.send(.home(.storyTapped(story))) {
      $0.path = [.reading(Reading.State.DebugSnapshot(
        bigWords: big, friend: friend, locksStories: false, look: "scarf", treat: treat,
        story: story
      ))]
    }
    #expect(store.state.storyOnScreen == story)

    await store.receive(\.path) {
      $0.path = [
        .reading(
          Reading.State.DebugSnapshot(
            authorization: .authorized, bigWords: big, friend: friend, locksStories: false,
            look: "scarf", treat: treat, story: story
          )
        )
      ]
    }
    await store.dismount()
  }

  @Test func theOpenStoryWearsWhatWasTriedOn() async {
    let story = StoryLibrary.all[0]
    let item = WardrobeLibrary.unlockable(for: story.friend)[0]
    var tried = Content.Progress()
    tried.wear(item, on: story.friend)
    let saved = tried
    var state = Root.State()
    state.intro = nil
    state.path = [.reading(Reading.State(story, on: Content.Progress()))]
    state.wardrobe = Wardrobe.State(friend: story.friend)
    let store = TestStore(initialState: state) {
      Root()
        .dependency(ProgressStore(load: { saved }, save: { _ in }))
    } changes: {
      $0.wardrobe?.progress = saved
    }
    await store.receive(\.path) {
      try? $0.path[0].modify(\.reading) { $0.authorization = .authorized }
    }
    await store.send(to: \.wardrobe, .doneTapped) {
      $0.wardrobe = nil
      try? $0.path[0].modify(\.reading) { $0.look = item.id }
    }?.value
    await store.dismount()
  }
}
