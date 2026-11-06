import ComposableArchitecture
import ConcurrencyExtras
import Content
import DependenciesTestSupport
import Testing

@testable import GrownUps

@MainActor
@Suite(.steady, .serialized, .dependency(\.continuousClock, .immediate), .timeLimit(.minutes(1)))
struct PaywallTests {
  private let waits = Duration.seconds(5)

  private func paywall(
    _ purchases: PurchasesClient
  ) -> TestStore<some FeatureProtocol<Paywall.State, Paywall.Action>> {
    TestStore(initialState: Paywall.State()) {
      Paywall()
        .dependency(purchases)
    }
  }

  @Test func theOffersLoadYearlyFirst() async {
    let store = paywall(.fake(offers: PlusOffer.samples.reversed()))
    await store.receive(\.offersLoaded, timeout: waits) { $0.offers = .loaded(PlusOffer.samples) }
    await store.dismount()
  }

  @Test func offersThatFailToLoadShowTheMessage() async {
    let store = paywall(.fake(offers: nil))
    await store.receive(\.offersFailed, timeout: waits) { $0.offers = .unavailable }
    await store.dismount()
  }

  @Test func noOffersShowTheMessage() async {
    let store = paywall(.fake(offers: []))
    await store.receive(\.offersLoaded, timeout: waits) { $0.offers = .unavailable }
    await store.dismount()
  }

  @Test func buyingSubscribes() async {
    let store = paywall(.fake(outcome: .purchased))
    await store.receive(\.offersLoaded, timeout: waits) { $0.offers = .loaded(PlusOffer.samples) }
    store.send(.planTapped(.monthly)) { $0.selected = .monthly }
    store.send(.subscribeTapped) { $0.work = .subscribing }
    await store.receive(\.purchaseCompleted, timeout: waits) {
      $0.work = nil
      $0.isSubscribed = true
    }
    await store.receive(key: PlusSubscribed.self, timeout: waits)
    await store.dismount()
  }

  @Test func subscribingWaitsForThePlans() async {
    let store = paywall(.fake(offers: nil))
    await store.receive(\.offersFailed, timeout: waits) { $0.offers = .unavailable }
    store.send(.subscribeTapped)
    await store.dismount()
  }

  @Test func aSecondTapWhileBuyingIsIgnored() async {
    let purchases = LockIsolated(0)
    var client = PurchasesClient.fake(outcome: .cancelled)
    client.purchase = { _ in
      purchases.withValue { $0 += 1 }
      try await Task.never()
      return .cancelled
    }
    let store = paywall(client)
    await store.receive(\.offersLoaded, timeout: waits) { $0.offers = .loaded(PlusOffer.samples) }
    store.send(.subscribeTapped) { $0.work = .subscribing }
    store.send(.subscribeTapped)
    store.send(.planTapped(.monthly))
    store.send(.restoreTapped)
    await Task.yield()
    #expect(purchases.value == 1)
    await store.dismount()
  }

  @Test func cancellingChangesNothing() async {
    let store = paywall(.fake(outcome: .cancelled))
    await store.receive(\.offersLoaded, timeout: waits) { $0.offers = .loaded(PlusOffer.samples) }
    store.send(.subscribeTapped) { $0.work = .subscribing }
    await store.receive(\.purchaseCompleted, timeout: waits) { $0.work = nil }
    await store.dismount()
  }

  @Test func aPendingPurchaseWaits() async {
    let store = paywall(.fake(outcome: .pending))
    await store.receive(\.offersLoaded, timeout: waits) { $0.offers = .loaded(PlusOffer.samples) }
    store.send(.subscribeTapped) { $0.work = .subscribing }
    await store.receive(\.purchaseCompleted, timeout: waits) {
      $0.work = nil
      $0.isPending = true
    }
    await store.dismount()
  }

  @Test func restoringFindsPlus() async {
    let store = paywall(.fake(restores: true))
    await store.receive(\.offersLoaded, timeout: waits) { $0.offers = .loaded(PlusOffer.samples) }
    store.send(.restoreTapped) { $0.work = .restoring }
    await store.receive(\.restoreCompleted, timeout: waits) {
      $0.work = nil
      $0.isSubscribed = true
    }
    await store.receive(key: PlusSubscribed.self, timeout: waits)
    await store.dismount()
  }

  @Test func restoringWithNothingToRestoreSaysSo() async {
    let store = paywall(.fake(restores: false))
    await store.receive(\.offersLoaded, timeout: waits) { $0.offers = .loaded(PlusOffer.samples) }
    store.send(.restoreTapped) { $0.work = .restoring }
    await store.receive(\.restoreCompleted, timeout: waits) {
      $0.work = nil
      $0.foundNothingToRestore = true
    }
    await store.dismount()
  }

  @Test func aSubscriberOpeningThePaywallIsNotSentAway() async {
    let store = paywall(.fake(isPlus: true))
    await store.receive(\.offersLoaded, timeout: waits) { $0.offers = .loaded(PlusOffer.samples) }
    await store.dismount()
  }

  @Test func passingTheGateOpensThePaywallWithTheWelcome() async {
    let welcome = PlusWelcome(story: StoryLibrary.all[0], friend: .hare, meetsFriend: false)
    let store = TestStore(initialState: GrownUpPaywall.State(seed: 1, welcome: welcome)) {
      GrownUpPaywall()
        .dependency(PurchasesClient.fake(offers: nil))
    }
    store.send(.gate(.digitTapped(1))) { $0.gate?.entry = "1" }
    store.send(.gate(.digitTapped(5))) { $0.gate?.entry = "15" }
    store.send(.gate(.answerTapped))
    await store.receive(\.gate.passed, timeout: waits) {
      $0.paywall = Paywall.State.DebugSnapshot(welcome: welcome)
    }
    await store.receive(\.paywall.offersFailed, timeout: waits) {
      $0.paywall?.offers = .unavailable
    }
    await store.dismount()
  }
}
