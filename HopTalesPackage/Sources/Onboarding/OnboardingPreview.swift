import ComposableArchitecture2
import Content
import DesignSystem
import SwiftUI

#if DEBUG
struct OnboardingPreview: View {
  let step: Onboarding.Step
  let size: CGSize

  init(_ step: Onboarding.Step, size: CGSize = Metrics.phone.reference) {
    self.step = step
    self.size = size
  }

  var body: some View {
    OnboardingScreen(store: Store(initialState: state) {
      Onboarding().dependency(
        CloudSync(account: { .signedOut }, isEnabled: { false }, setEnabled: { _ in })
      )
    })
      .frame(width: size.width, height: size.height)
  }

  private var state: Onboarding.State {
    var state = Onboarding.State()
    state.childName = "Wren"
    state.path = Onboarding.Step.allCases.filter { $0 != .cloud && $0.rawValue <= step.rawValue }
    if step.rawValue > Onboarding.Step.listening.rawValue { state.authorization = .authorized }
    if step == .friend { state.startingFriend = .hare }
    if step == .soundButtons {
      state.startingFriend = .bunny
      state.soundButtons = true
    }
    if step.rawValue > Onboarding.Step.cloud.rawValue { state.cloudSync = false }
    if step == .cloud {
      state.cloudSync = true
      state.cloudAccount = .signedOut
    }
    return state
  }
}

#Preview("iCloud") { OnboardingPreview(.cloud) }
#Preview("Name") { OnboardingPreview(.name) }
#Preview("Microphone") { OnboardingPreview(.listening) }
#Preview("Starting friend") { OnboardingPreview(.friend) }
#Preview("Sound buttons") { OnboardingPreview(.soundButtons) }
#endif
