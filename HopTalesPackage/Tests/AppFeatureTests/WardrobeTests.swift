import ComposableArchitecture2
import Content
import Dependencies
import Testing

@testable import Home

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct WardrobeFeatureTests {
  nonisolated private static var progress: Content.Progress {
    var basket = Basket()
    basket.filled = 4
    return Content.Progress(journey: Journey(starting: .hare), baskets: [.hare: basket])
  }

  @Test func everyItemIsInOneGridAndTappingSwapsTheLook() async {
    let saved = LockIsolated(Self.progress)
    let store = TestStore(initialState: Wardrobe.State(friend: .hare)) {
      Wardrobe()
        .dependency(ProgressStore(load: { saved.value }, save: { saved.setValue($0) }))
    } changes: {
      $0.progress = Self.progress
    }
    let items = WardrobeLibrary.items(for: .hare)
    #expect(store.state.items == items)

    store.send(.itemTapped(items[0])) {
      $0.progress.outfits[.hare] = [items[0].slot: items[0].id]
    }
    store.send(.itemTapped(items[1])) {
      $0.progress.outfits[.hare] = [items[1].slot: items[1].id]
    }
    #expect(saved.value.outfit(for: .hare) == [items[1]])
    await store.dismount()
  }

  @Test func tappingTheWornItemOrJustMeTakesTheLookOff() async {
    let saved = LockIsolated(Self.progress)
    let store = TestStore(initialState: Wardrobe.State(friend: .hare)) {
      Wardrobe()
        .dependency(ProgressStore(load: { saved.value }, save: { saved.setValue($0) }))
    } changes: {
      $0.progress = Self.progress
    }
    let item = WardrobeLibrary.items(for: .hare)[0]

    store.send(.itemTapped(item)) { $0.progress.outfits[.hare] = [item.slot: item.id] }
    store.send(.itemTapped(item)) { $0.progress.outfits[.hare] = [:] }
    store.send(.itemTapped(item)) { $0.progress.outfits[.hare] = [item.slot: item.id] }
    store.send(.justMeTapped) { $0.progress.outfits[.hare] = nil }
    #expect(saved.value.outfit(for: .hare).isEmpty)
    await store.dismount()
  }
}
