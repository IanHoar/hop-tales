import ComposableArchitecture
import ConcurrencyExtras
import Content
import DependenciesTestSupport
import Testing

@testable import Home

@MainActor
@Suite(.steady, .timeLimit(.minutes(1)))
struct HomeFeatureTests {
  nonisolated private static var progress: Content.Progress {
    Content.Progress(journey: Journey(starting: .hare))
  }

  @Test func theGreetingFollowsTheHourOfTheDay() async {
    let store = TestStore(initialState: Home.State(childName: "Wren")) {
      Home()
        .dependency(ProgressStore(load: { Self.progress }, save: { _ in }))
    }
    #expect(store.state.hour == 8)
    #expect(store.state.progress == Self.progress)
    await store.dismount()
  }

  @Test func plusArrivingFromTheStoreUnlocksHome() async {
    let (plus, arrives) = AsyncStream.makeStream(of: Bool.self)
    var purchases = PurchasesClient.fake()
    purchases.isPlus = { plus }
    var state = Home.State(childName: "Wren")
    state.hour = 9
    state.locksStories = true
    let store = TestStore(initialState: state) {
      Home()
        .dependency(purchases)
    }
    arrives.yield(true)
    await store.receive(\.plusChanged) { $0.isPlus = true }
    arrives.finish()
    await store.dismount()
  }

  @Test func readingWithAMetFriendIsSavedAndAStrangerIsIgnored() async {
    let saved = LockIsolated(Self.progress)
    let store = TestStore(initialState: Friends.State()) {
      Friends()
        .dependency(ProgressStore(load: { saved.value }, save: { saved.setValue($0) }))
    } changes: {
      $0.progress = Self.progress
    }

    store.send(.friendTapped(.crow))
    store.send(.friendTapped(.bunny)) {
      $0.progress.journey.readWith(.bunny)
    }
    #expect(saved.value.journey.activeFriend == .bunny)
    await store.send(.doneTapped)?.value
    #expect(!store.isPresented)
  }

  @Test func theBookOnlyOpensOnFriendsAlreadyMet() async {
    let store = TestStore(initialState: Book.State(friend: .hare)) {
      Book()
        .dependency(ProgressStore(load: { Self.progress }, save: { _ in }))
    } changes: {
      $0.progress = Self.progress
    }

    store.send(.friendPicked(.crow))
    store.send(.friendPicked(.bunny)) { $0.friend = .bunny }
    await store.send(.doneTapped)?.value
    #expect(!store.isPresented)
  }
}
