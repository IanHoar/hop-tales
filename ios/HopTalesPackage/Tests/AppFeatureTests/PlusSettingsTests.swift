import ComposableArchitecture
import Content
import Dependencies
import Foundation
import Testing

@testable import GrownUps

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct PlusSettingsTests {
  static let renewing = PlusStatus(
    .renews(Date(timeIntervalSince1970: 1_772_496_000)), refundableTransactionID: 7
  )

  nonisolated static func plus() -> AsyncStream<Bool> {
    AsyncStream { continuation in
      continuation.yield(true)
      continuation.finish()
    }
  }

  private func settings(
    _ purchases: PurchasesClient,
    _ status: PlusStatus = .free
  ) -> TestStore<some FeatureProtocol<Settings.State, Settings.Action>> {
    var state = Settings.State()
    state.plusStatus = status
    return TestStore(initialState: state) {
      Settings()
        .dependency(ProfileStore(load: { nil }, save: { _ in }))
        .dependency(purchases)
    }
  }

  private func answerTheGate(
    _ store: TestStore<some FeatureProtocol<Settings.State, Settings.Action>>
  ) {
    store.send(.gate(.digitTapped(1))) { $0.gate?.entry = "1" }
    store.send(.gate(.digitTapped(5))) { $0.gate?.entry = "15" }
    store.send(.gate(.answerTapped))
  }

  @Test func aFreeReaderShowsFreeWithNothingToLoad() async {
    let store = settings(.fake())
    await store.dismount()
  }

  @Test func theStatusComesFromTheStore() async {
    let store = settings(.fake(isPlus: true, status: Self.renewing))
    await store.receive(\.subscription.statusResolved) { $0.plusStatus = Self.renewing }
    await store.dismount()
  }

  @Test func plusWithoutDetailsStillSaysPlus() async {
    let store = settings(.fake(isPlus: true))
    await store.receive(\.subscription.statusResolved) { $0.plusStatus = PlusStatus(.plus) }
    await store.dismount()
  }

  @Test func aPaymentProblemShowsWhileTheEntitlementHasLapsed() async {
    let problem = PlusStatus(.paymentProblem, refundableTransactionID: 7)
    let store = settings(.fake(isPlus: false, status: problem))
    await store.receive(\.subscription.statusResolved) { $0.plusStatus = problem }
    await store.dismount()
  }

  @Test func familySharingSaysSo() async {
    let shared = PlusStatus(.familyShared)
    let store = settings(.fake(isPlus: true, status: shared))
    await store.receive(\.subscription.statusResolved) { $0.plusStatus = shared }
    await store.dismount()
  }

  @Test func subscribeGoesThroughTheGateToThePaywall() async {
    let store = settings(.fake())
    store.send(.subscription(.subscribeTapped)) {
      $0.grownUp = GrownUpPaywall.State.DebugSnapshot(
        isOnboarding: false, gate: ParentGate.State.DebugSnapshot(seed: 1)
      )
    }
    store.send(.grownUp(.gate(.digitTapped(1)))) { $0.grownUp?.gate?.entry = "1" }
    store.send(.grownUp(.gate(.digitTapped(5)))) { $0.grownUp?.gate?.entry = "15" }
    store.send(.grownUp(.gate(.answerTapped)))
    await store.receive(\.grownUp.gate.passed) {
      $0.grownUp?.gate = nil
      $0.grownUp?.paywall = Paywall.State.DebugSnapshot(isOnboarding: false)
    }
    await store.receive(\.grownUp.paywall.offersLoaded) {
      $0.grownUp?.paywall?.offers = .loaded(PlusOffer.samples)
    }
    store.send(.grownUp(.paywall(.closeTapped))) { $0.grownUp = nil }
    await store.dismount()
  }

  @Test func leavingTheGateDoesNothing() async {
    let store = settings(.fake())
    store.send(.subscription(.manageTapped)) {
      $0.gatedRequest = .manage
      $0.gate = ParentGate.State.DebugSnapshot(seed: 1)
    }
    store.send(.gate(.closeTapped)) {
      $0.gatedRequest = nil
      $0.gate = nil
    }
    await store.dismount()
  }

  @Test func restoreGoesThroughTheGateAndFindsPlus() async {
    let store = settings(PurchasesClient(start: {}, isPlus: { Self.plus() }, restore: { true }))
    await store.receive(\.subscription.statusResolved) { $0.plusStatus = PlusStatus(.plus) }
    store.send(.subscription(.restoreTapped)) {
      $0.gatedRequest = .restore
      $0.gate = ParentGate.State.DebugSnapshot(seed: 1)
    }
    answerTheGate(store)
    await store.receive(\.gate.passed) {
      $0.gatedRequest = nil
      $0.gate = nil
    }
    await store.receive(\.subscription.restored)
    await store.receive(\.subscription.statusResolved)
    await store.dismount()
  }

  @Test func restoringWithNothingToRestoreSaysSo() async {
    let store = settings(.fake(restores: false))
    store.send(.subscription(.restoreTapped)) {
      $0.gatedRequest = .restore
      $0.gate = ParentGate.State.DebugSnapshot(seed: 1)
    }
    answerTheGate(store)
    await store.receive(\.gate.passed) {
      $0.gatedRequest = nil
      $0.gate = nil
    }
    await store.receive(\.subscription.restored) { $0.foundNothingToRestore = true }
    await store.receive(\.subscription.statusResolved)
    await store.dismount()
  }

  @Test func manageGoesThroughTheGate() async {
    let store = settings(.fake(isPlus: true, status: Self.renewing), Self.renewing)
    await store.receive(\.subscription.statusResolved)
    store.send(.subscription(.manageTapped)) {
      $0.gatedRequest = .manage
      $0.gate = ParentGate.State.DebugSnapshot(seed: 1)
    }
    answerTheGate(store)
    await store.receive(\.gate.passed) {
      $0.gatedRequest = nil
      $0.gate = nil
      $0.isManagingSubscription = true
    }
    store.send(.subscription(.manageClosed)) { $0.isManagingSubscription = false }
    await store.receive(\.subscription.statusResolved)
    await store.dismount()
  }

  @Test func aRefundGoesThroughTheGate() async {
    let store = settings(.fake(isPlus: true, status: Self.renewing), Self.renewing)
    await store.receive(\.subscription.statusResolved)
    store.send(.subscription(.refundTapped)) {
      $0.gatedRequest = .refund
      $0.gate = ParentGate.State.DebugSnapshot(seed: 1)
    }
    answerTheGate(store)
    await store.receive(\.gate.passed) {
      $0.gatedRequest = nil
      $0.gate = nil
      $0.isRequestingRefund = true
    }
    store.send(.subscription(.refundClosed)) { $0.isRequestingRefund = false }
    await store.receive(\.subscription.statusResolved)
    await store.dismount()
  }
}
