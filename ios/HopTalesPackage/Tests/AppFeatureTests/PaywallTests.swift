import ComposableArchitecture2
import Content
import Testing

@testable import GrownUps

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct PaywallTests {
  private func paywall(
    _ purchases: PurchasesClient
  ) -> TestStore<some FeatureProtocol<Paywall.State, Paywall.Action>> {
    TestStore(initialState: Paywall.State()) {
      Paywall()
        .dependency(purchases)
    }
  }

  private func isPlus(_ purchases: PurchasesClient) async -> Bool? {
    for await isPlus in purchases.isPlus() { return isPlus }
    return nil
  }

  @Test func theOffersLoadYearlyFirst() async {
    let store = paywall(.fake(offers: PlusOffer.samples.reversed()))
    await store.receive(\.offersLoaded) { $0.offers = .loaded(PlusOffer.samples) }
    await store.dismount()
  }

  @Test func offersThatFailToLoadShowTheMessage() async {
    let store = paywall(.fake(offers: nil))
    await store.receive(\.offersFailed) { $0.offers = .unavailable }
    await store.dismount()
  }

  @Test func noOffersShowTheMessage() async {
    let store = paywall(.fake(offers: []))
    await store.receive(\.offersLoaded) { $0.offers = .unavailable }
    await store.dismount()
  }

  @Test func buyingFlipsTheEntitlement() async {
    let purchases = PurchasesClient.fake(outcome: .purchased)
    let store = paywall(purchases)
    await store.receive(\.offersLoaded) { $0.offers = .loaded(PlusOffer.samples) }
    store.send(.planTapped(.yearly))
    await store.receive(\.purchaseCompleted)
    await store.receive(\.subscribed)
    #expect(await isPlus(purchases) == true)
    await store.dismount()
  }

  @Test func cancellingChangesNothing() async {
    let purchases = PurchasesClient.fake(outcome: .cancelled)
    let store = paywall(purchases)
    await store.receive(\.offersLoaded) { $0.offers = .loaded(PlusOffer.samples) }
    store.send(.planTapped(.monthly))
    await store.receive(\.purchaseCompleted)
    #expect(await isPlus(purchases) == false)
    await store.dismount()
  }

  @Test func aPendingPurchaseWaitsAndIsNotPlus() async {
    let purchases = PurchasesClient.fake(outcome: .pending)
    let store = paywall(purchases)
    await store.receive(\.offersLoaded) { $0.offers = .loaded(PlusOffer.samples) }
    store.send(.planTapped(.yearly))
    await store.receive(\.purchaseCompleted) { $0.isPending = true }
    #expect(await isPlus(purchases) == false)
    await store.dismount()
  }

  @Test func restoringFindsPlus() async {
    let purchases = PurchasesClient.fake(restores: true)
    let store = paywall(purchases)
    await store.receive(\.offersLoaded) { $0.offers = .loaded(PlusOffer.samples) }
    store.send(.restoreTapped)
    await store.receive(\.subscribed)
    #expect(await isPlus(purchases) == true)
    await store.dismount()
  }

  @Test func restoringWithNothingToRestoreSaysSo() async {
    let store = paywall(.fake(restores: false))
    await store.receive(\.offersLoaded) { $0.offers = .loaded(PlusOffer.samples) }
    store.send(.restoreTapped)
    await store.receive(\.nothingToRestore) { $0.foundNothingToRestore = true }
    await store.dismount()
  }

  @Test func aSubscriberOpeningThePaywallIsNotSentAway() async {
    let store = paywall(.fake(isPlus: true))
    await store.receive(\.offersLoaded) { $0.offers = .loaded(PlusOffer.samples) }
    await store.dismount()
  }

  @Test func passingTheGateOpensTheOnboardingPaywall() async {
    let store = TestStore(initialState: GrownUpPaywall.State(seed: 1, isOnboarding: true)) {
      GrownUpPaywall()
        .dependency(PurchasesClient.fake(offers: nil))
    }
    store.send(.gate(.digitTapped(1))) { $0.gate?.entry = "1" }
    store.send(.gate(.digitTapped(5))) { $0.gate?.entry = "15" }
    store.send(.gate(.answerTapped))
    await store.receive(\.gate.passed) {
      $0.gate = nil
      $0.paywall = Paywall.State.DebugSnapshot(isOnboarding: true)
    }
    await store.receive(\.paywall.offersFailed) { $0.paywall?.offers = .unavailable }
    await store.dismount()
  }
}
