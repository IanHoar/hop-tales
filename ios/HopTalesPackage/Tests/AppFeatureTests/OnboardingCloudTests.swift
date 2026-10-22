import ComposableArchitecture2
import Content
import Dependencies
import SpeechRecognition
import Testing

@testable import Onboarding

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct OnboardingCloudTests {
  @Test func anICloudThatNeverAnswersStillLetsSetUpCarryOn() async {
    let store = TestStore(initialState: Onboarding.State()) {
      Onboarding()
        .dependency(OnboardingTests.speech)
        .dependency(ProfileStore(load: { nil }, save: { _ in }))
        .dependency(
          CloudSync(
            account: { .available },
            isEnabled: { true },
            setEnabled: { _ in },
            catchUp: { try? await Task.sleep(for: .seconds(3600)) },
            catchUpLimit: .milliseconds(50)
          )
        )
    }
    store.send(.cloudSyncPicked(true)) { $0.cloudSync = true }
    await store.receive(\.cloudAccountResolved, timeout: .seconds(2)) {
      $0.cloudAccount = .available
    }
    store.send(.primaryTapped) { $0.isCatchingUp = true }
    await store.receive(\.cloudCaughtUp, timeout: .seconds(2)) {
      $0.isCatchingUp = false
      $0.path = [.name]
    }
  }

  @Test func anICloudThatNeverStartsStillLetsSetUpCarryOn() async {
    let store = TestStore(initialState: Onboarding.State()) {
      Onboarding()
        .dependency(OnboardingTests.speech)
        .dependency(ProfileStore(load: { nil }, save: { _ in }))
        .dependency(
          CloudSync(
            account: { .available },
            isEnabled: { false },
            setEnabled: { _ in try? await Task.sleep(for: .seconds(3600)) },
            catchUpLimit: .milliseconds(50)
          )
        )
    }
    store.send(.cloudSyncPicked(true)) { $0.cloudSync = true }
    await store.receive(\.cloudAccountResolved, timeout: .seconds(2)) {
      $0.cloudAccount = .available
    }
    store.send(.primaryTapped) { $0.isCatchingUp = true }
    await store.receive(\.cloudCaughtUp, timeout: .seconds(2)) {
      $0.isCatchingUp = false
      $0.path = [.name]
    }
  }
}
