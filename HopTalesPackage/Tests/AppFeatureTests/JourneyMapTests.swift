import ComposableArchitecture2
import Content
import Testing

@testable import Home

@MainActor
struct JourneyMapTests {
  @Test func eachFriendShowsWhereTheyAreOnTheJourney() {
    var state = JourneyMap.State()
    state.journey = Journey(starting: .hare)
    #expect(state.stop(for: .bunny) == .met)
    #expect(state.stop(for: .hare) == .reading)
    #expect(state.stop(for: .frog) == .next(bigStoryWaiting: false))
    #expect(state.stop(for: .crow) == .later)
    state.journey.steps = state.journey.goal
    #expect(state.stop(for: .frog) == .next(bigStoryWaiting: true))
  }
}
