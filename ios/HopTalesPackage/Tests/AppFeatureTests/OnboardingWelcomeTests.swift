import ComposableArchitecture2
import Content
import Dependencies
import Testing

@testable import Onboarding

@MainActor
struct OnboardingWelcomeTests {
  @Test func theWelcomeComesBeforeTheFirstStep() async {
    let store = TestStore(initialState: Onboarding.State(welcoming: true)) {
      Onboarding().dependency(OnboardingTests.speech)
    }
    #expect(store.state.primaryTitle == "Get started")
    #expect(store.state.primaryEnabled)
    store.send(.primaryTapped) { $0.isWelcoming = false }
    #expect(store.state.step == .cloud)
    #expect(store.state.stepNumber == 1)
    #expect(!store.state.primaryEnabled)
  }

  @Test func backFromTheFirstStepReturnsToTheWelcome() async {
    let store = TestStore(initialState: Onboarding.State()) {
      Onboarding().dependency(OnboardingTests.speech)
    }
    store.send(.backTapped) { $0.isWelcoming = true }
    store.send(.primaryTapped) { $0.isWelcoming = false }
  }

  @Test func resumingSkipsTheWelcome() {
    let state = Onboarding.State(resuming: ProfileDraft(childName: "Maya", step: 2))
    #expect(!state.isWelcoming)
    #expect(state.step == .name)
  }

  @Test func gettingStartedSavesADraftAtTheFirstStep() {
    let saved = LockIsolated<ProfileDraft?>(nil)
    let store = TestStore(initialState: Onboarding.State(welcoming: true)) {
      Onboarding()
        .dependency(OnboardingTests.speech)
        .dependency(
          ProfileStore(load: { nil }, save: { _ in }, saveDraft: { saved.setValue($0) })
        )
    }
    store.send(.primaryTapped) { $0.isWelcoming = false }
    #expect(saved.value?.step == Onboarding.Step.cloud.rawValue)
  }
}
