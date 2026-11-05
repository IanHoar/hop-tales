import ComposableArchitecture
import Content
import DependenciesTestSupport
import Testing

@testable import Home

@MainActor
@Suite(.steady)
struct JourneyMapTests {
  @Test func eachFriendShowsWhereTheyAreOnTheJourney() {
    var state = JourneyMap.State()
    state.journey = Journey(starting: .hare)
    #expect(state.stop(for: .bunny) == .met)
    #expect(state.stop(for: .hare) == .reading)
    #expect(state.stop(for: .frog) == .next(bigStoryWaiting: false))
    #expect(state.stop(for: .crow) == .later)
    state.journey.steps = state.journey.goal
    #expect(state.stop(for: .frog) == .next(bigStoryWaiting: false))
    state.journey.storiesRead = Set(StoryLibrary.stories(at: 2).map(\.id))
    #expect(state.stop(for: .frog) == .next(bigStoryWaiting: true))
  }

  @Test func aWaitingBigStoryIsChosenAndOtherStopsAreNot() async {
    var progress = Content.Progress(journey: Journey(starting: .hare))
    progress.journey.steps = progress.journey.goal
    progress.journey.storiesRead = Set(StoryLibrary.stories(at: 2).map(\.id))
    let saved = progress
    var state = JourneyMap.State()
    state.journey = saved.journey
    let store = TestStore(initialState: state) {
      JourneyMap()
        .dependency(ProgressStore(load: { saved }, save: { _ in }))
    }
    store.send(.stopTapped(.crow))
    store.send(.stopTapped(.frog))
    await store.receive(key: StoryChosen.self)
    await store.dismount()
  }
}
