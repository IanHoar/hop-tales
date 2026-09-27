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
    store.send(.justMeTapped) { $0.progress.outfits[.hare] = [:] }
    #expect(saved.value.outfit(for: .hare).isEmpty)
    await store.dismount()
  }

  @Test func bobWearsHisBowUntilSomethingElseIsChosen() async throws {
    var basket = Basket()
    basket.filled = 1
    let fresh = Content.Progress(baskets: [.bunny: basket])
    let saved = LockIsolated(fresh)
    let store = TestStore(initialState: Wardrobe.State(friend: .bunny)) {
      Wardrobe()
        .dependency(ProgressStore(load: { saved.value }, save: { saved.setValue($0) }))
    } changes: {
      $0.progress = fresh
    }
    let items = WardrobeLibrary.items(for: .bunny)
    let bow = try #require(items.first { $0.id == "bow" })
    let crown = try #require(items.first { $0.id == "bluebell-crown" })
    #expect(store.state.outfit == [bow])

    store.send(.itemTapped(crown)) { $0.progress.outfits[.bunny] = [.head: crown.id] }
    #expect(saved.value.outfit(for: .bunny) == [crown])
    store.send(.itemTapped(bow)) { $0.progress.outfits[.bunny] = [.head: bow.id] }
    store.send(.itemTapped(bow)) { $0.progress.outfits[.bunny] = [:] }
    #expect(saved.value.outfit(for: .bunny).isEmpty)
    await store.dismount()
  }

  @Test func justMeTakesOffBobsStartingBow() async {
    let saved = LockIsolated(Content.Progress())
    let store = TestStore(initialState: Wardrobe.State(friend: .bunny)) {
      Wardrobe()
        .dependency(ProgressStore(load: { saved.value }, save: { saved.setValue($0) }))
    }
    #expect(store.state.outfit.map(\.id) == ["bow"])

    store.send(.justMeTapped) { $0.progress.outfits[.bunny] = [:] }
    #expect(store.state.outfit.isEmpty)
    #expect(saved.value.outfit(for: .bunny).isEmpty)
    await store.dismount()
  }
}
