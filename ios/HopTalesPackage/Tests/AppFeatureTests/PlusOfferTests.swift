import ComposableArchitecture2
import Content
import Dependencies
import Testing

@testable import AppFeature
@testable import GrownUps
@testable import Home
@testable import Onboarding

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct PlusOfferTests {
  private static let maya = Profile(childName: "Maya")

  private static func root(isPlus: Bool = false, locksStories: Bool = true) -> Root.State {
    var state = Root.State()
    state.intro = nil
    state.home.locksStories = locksStories
    state.home.isPlus = isPlus
    return state
  }

  private static func offering() -> Root.State {
    var state = root(locksStories: false)
    state.plusOffer = GrownUpPaywall.State(seed: 1, isOnboarding: true)
    return state
  }

  private static func profiles(_ saved: LockIsolated<Profile?>) -> ProfileStore {
    ProfileStore(
      load: { saved.value }, save: { saved.setValue($0) }, erase: { saved.setValue(nil) }
    )
  }

  private static func gate() -> GrownUpPaywall.State.DebugSnapshot {
    GrownUpPaywall.State.DebugSnapshot(
      isOnboarding: true, gate: ParentGate.State.DebugSnapshot(seed: 1)
    )
  }

  @Test func theLastStepOpensTheGateAndRemembersTheOffer() async {
    let saved = LockIsolated<Profile?>(nil)
    let store = TestStore(initialState: Self.root()) {
      Root().dependency(Self.profiles(saved))
    } changes: {
      $0.onboarding = Onboarding.State.DebugSnapshot()
    }
    store.send(.onboarding(.finished(Self.maya))) {
      $0.onboarding = nil
      $0.home.childName = "Maya"
      $0.plusOffer = Self.gate()
    }
    #expect(saved.value?.plusOffered == true)
    #expect(saved.value?.childName == "Maya")
    await store.dismount()
  }

  @Test func aReaderWhoWasOfferedIsNeverOfferedAgain() async {
    let saved = LockIsolated<Profile?>(Profile(childName: "Maya", plusOffered: true))
    var state = Self.root()
    state.onboarding = Onboarding.State()
    let store = TestStore(initialState: state) {
      Root().dependency(Self.profiles(saved))
    } changes: {
      $0.home.childName = "Maya"
    }
    store.send(.onboarding(.finished(Self.maya))) {
      $0.onboarding = nil
    }
    #expect(saved.value?.plusOffered == true)
    await store.dismount()
  }

  @Test func aReaderWhoIsAlreadyPlusIsNotOffered() async {
    let saved = LockIsolated<Profile?>(nil)
    let store = TestStore(initialState: Self.root(isPlus: true)) {
      Root()
        .dependency(Self.profiles(saved))
        .dependency(PurchasesClient.fixed(true))
    } changes: {
      $0.onboarding = Onboarding.State.DebugSnapshot()
    }
    store.send(.onboarding(.finished(Self.maya))) {
      $0.onboarding = nil
      $0.home.childName = "Maya"
    }
    #expect(saved.value?.plusOffered == false)
    await store.dismount()
  }

  @Test func theReleaseSwitchSkipsTheOffer() {
    #expect(Root.State().home.locksStories == Plus.locksStories)
    let saved = LockIsolated<Profile?>(nil)
    let store = TestStore(initialState: Self.root(locksStories: false)) {
      Root().dependency(Self.profiles(saved))
    } changes: {
      $0.onboarding = Onboarding.State.DebugSnapshot()
    }
    store.send(.onboarding(.finished(Self.maya))) {
      $0.onboarding = nil
      $0.home.childName = "Maya"
    }
    #expect(saved.value?.plusOffered == false)
  }

  @Test func closingTheGateStartsOnHome() {
    let store = TestStore(initialState: Self.offering()) {
      Root()
    }
    store.send(.plusOffer(.gate(.closeTapped))) { $0.plusOffer = nil }
    #expect(store.state.onboarding == nil)
    #expect(store.state.path.isEmpty)
  }

  @Test func tryLevelOneFreeStartsOnHome() async {
    let store = TestStore(initialState: Self.offering()) {
      Root().dependency(PurchasesClient.fake())
    }
    store.send(.plusOffer(.gate(.passed))) {
      $0.plusOffer?.gate = nil
      $0.plusOffer?.paywall = Paywall.State.DebugSnapshot(isOnboarding: true)
    }
    await store.receive(\.plusOffer.paywall.offersLoaded) {
      $0.plusOffer?.paywall?.offers = .loaded(PlusOffer.samples)
    }
    store.send(.plusOffer(.paywall(.tryLevelOneTapped))) { $0.plusOffer = nil }
    #expect(!store.state.home.isPlus)
    await store.dismount()
  }

  @Test func closingThePaywallStartsOnHome() async {
    var state = Self.offering()
    state.plusOffer?.gate = nil
    state.plusOffer?.paywall = Paywall.State(isOnboarding: true)
    let store = TestStore(initialState: state) {
      Root().dependency(PurchasesClient.fake())
    }
    await store.receive(\.plusOffer.paywall.offersLoaded) {
      $0.plusOffer?.paywall?.offers = .loaded(PlusOffer.samples)
    }
    store.send(.plusOffer(.paywall(.closeTapped))) { $0.plusOffer = nil }
    await store.dismount()
  }

  @Test func buyingStartsOnHomeAsPlus() async {
    var state = Self.offering()
    state.plusOffer?.gate = nil
    state.plusOffer?.paywall = Paywall.State(isOnboarding: true)
    let store = TestStore(initialState: state) {
      Root().dependency(PurchasesClient.fake())
    }
    await store.receive(\.plusOffer.paywall.offersLoaded) {
      $0.plusOffer?.paywall?.offers = .loaded(PlusOffer.samples)
    }
    store.send(.plusOffer(.paywall(.planTapped(.yearly))))
    await store.receive(\.plusOffer.paywall.purchaseCompleted)
    await store.receive(\.plusOffer.paywall.subscribed) {
      $0.plusOffer = nil
      $0.home.isPlus = true
    }
    await store.dismount()
  }

  @Test func resettingOnboardingOffersPlusAgain() async {
    let saved = LockIsolated<Profile?>(Profile(childName: "Maya", plusOffered: true))
    var state = Self.root()
    state.settings = Settings.State()
    let store = TestStore(initialState: state) {
      Root().dependency(Self.profiles(saved))
    } changes: {
      $0.home.childName = "Maya"
      $0.settings?.childName = "Maya"
      $0.settings?.profile = Profile(childName: "Maya", plusOffered: true)
    }
    store.send(.settings(.resetOnboardingTapped)) {
      $0.home.childName = nil
      $0.onboarding = Onboarding.State.DebugSnapshot()
      $0.settings = nil
    }
    #expect(saved.value == nil)
    store.send(.onboarding(.finished(Self.maya))) {
      $0.onboarding = nil
      $0.home.childName = "Maya"
      $0.plusOffer = Self.gate()
    }
    #expect(saved.value?.plusOffered == true)
    await store.dismount()
  }
}
