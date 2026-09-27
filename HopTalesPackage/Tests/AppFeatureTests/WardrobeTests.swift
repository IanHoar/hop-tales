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
    return Content.Progress(journey: Journey(starting: .cat), baskets: [.cat: basket])
  }

  @Test func everyItemIsInOneGridAndTappingSwapsTheLook() async {
    let saved = LockIsolated(Self.progress)
    let store = TestStore(initialState: Wardrobe.State(friend: .cat)) {
      Wardrobe()
        .dependency(ProgressStore(load: { saved.value }, save: { saved.setValue($0) }))
    } changes: {
      $0.progress = Self.progress
    }
    let items = WardrobeLibrary.items(for: .cat)
    #expect(store.state.items == items)

    store.send(.itemTapped(items[0])) {
      $0.progress.outfits[.cat] = [items[0].slot: items[0].id]
    }
    store.send(.itemTapped(items[1])) {
      $0.progress.outfits[.cat] = [items[1].slot: items[1].id]
    }
    #expect(saved.value.outfit(for: .cat) == [items[1]])
    await store.dismount()
  }

  @Test func tappingTheWornItemOrJustMeTakesTheLookOff() async {
    let saved = LockIsolated(Self.progress)
    let store = TestStore(initialState: Wardrobe.State(friend: .cat)) {
      Wardrobe()
        .dependency(ProgressStore(load: { saved.value }, save: { saved.setValue($0) }))
    } changes: {
      $0.progress = Self.progress
    }
    let item = WardrobeLibrary.items(for: .cat)[0]

    store.send(.itemTapped(item)) { $0.progress.outfits[.cat] = [item.slot: item.id] }
    store.send(.itemTapped(item)) { $0.progress.outfits[.cat] = [:] }
    store.send(.itemTapped(item)) { $0.progress.outfits[.cat] = [item.slot: item.id] }
    store.send(.justMeTapped) { $0.progress.outfits[.cat] = [:] }
    #expect(saved.value.outfit(for: .cat).isEmpty)
    await store.dismount()
  }

  @Test func bobWearsHisBowUntilSomethingElseIsChosen() async throws {
    let saved = LockIsolated(Content.Progress())
    let store = TestStore(initialState: Wardrobe.State(friend: .bunny)) {
      Wardrobe()
        .dependency(ProgressStore(load: { saved.value }, save: { saved.setValue($0) }))
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

  @Test func skipWearsHisScarfUntilSomethingElseIsChosen() async throws {
    let fresh = Content.Progress(journey: Journey(starting: .hare))
    let saved = LockIsolated(fresh)
    let store = TestStore(initialState: Wardrobe.State(friend: .hare)) {
      Wardrobe()
        .dependency(ProgressStore(load: { saved.value }, save: { saved.setValue($0) }))
    } changes: {
      $0.progress = fresh
    }
    let items = WardrobeLibrary.items(for: .hare)
    let scarf = try #require(items.first { $0.id == "scarf" })
    let straw = try #require(items.first { $0.id == "straw" })
    #expect(store.state.outfit == [scarf])

    store.send(.itemTapped(straw)) { $0.progress.outfits[.hare] = [.head: straw.id] }
    #expect(saved.value.outfit(for: .hare) == [straw])
    store.send(.justMeTapped) { $0.progress.outfits[.hare] = [:] }
    #expect(saved.value.outfit(for: .hare).isEmpty)
    await store.dismount()
  }

  @Test func oggyWearsHisNeckerchiefUntilSomethingElseIsChosen() async throws {
    let fresh = Content.Progress(journey: Journey(starting: .frog))
    let saved = LockIsolated(fresh)
    let store = TestStore(initialState: Wardrobe.State(friend: .frog)) {
      Wardrobe()
        .dependency(ProgressStore(load: { saved.value }, save: { saved.setValue($0) }))
    } changes: {
      $0.progress = fresh
    }
    let items = WardrobeLibrary.items(for: .frog)
    let neckerchief = try #require(items.first { $0.id == "neckerchief" })
    let hat = try #require(items.first { $0.id == "lilypad-hat" })
    #expect(store.state.outfit == [neckerchief])

    store.send(.itemTapped(hat)) { $0.progress.outfits[.frog] = [.head: hat.id] }
    #expect(saved.value.outfit(for: .frog) == [hat])
    store.send(.justMeTapped) { $0.progress.outfits[.frog] = [:] }
    #expect(saved.value.outfit(for: .frog).isEmpty)
    await store.dismount()
  }

  @Test func buttonWearsHisKnitCapUntilSomethingElseIsChosen() async throws {
    let fresh = Content.Progress(journey: Journey(starting: .crow))
    let saved = LockIsolated(fresh)
    let store = TestStore(initialState: Wardrobe.State(friend: .crow)) {
      Wardrobe()
        .dependency(ProgressStore(load: { saved.value }, save: { saved.setValue($0) }))
    } changes: {
      $0.progress = fresh
    }
    let items = WardrobeLibrary.items(for: .crow)
    let cap = try #require(items.first { $0.id == "knit-cap" })
    let flatCap = try #require(items.first { $0.id == "flat-cap" })
    #expect(store.state.outfit == [cap])

    store.send(.itemTapped(flatCap)) { $0.progress.outfits[.crow] = [.head: flatCap.id] }
    #expect(saved.value.outfit(for: .crow) == [flatCap])
    store.send(.justMeTapped) { $0.progress.outfits[.crow] = [:] }
    #expect(saved.value.outfit(for: .crow).isEmpty)
    await store.dismount()
  }
}
