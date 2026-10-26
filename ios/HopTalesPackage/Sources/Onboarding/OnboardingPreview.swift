import ComposableArchitecture
import Content
import DesignSystem
import SwiftUI

#if DEBUG
struct OnboardingPreview: View {
  let step: Onboarding.Step
  let size: CGSize
  let welcoming: Bool

  init(_ step: Onboarding.Step, size: CGSize = Metrics.phone.reference) {
    self.step = step
    self.size = size
    welcoming = false
  }

  init(welcomeOn size: CGSize = Metrics.phone.reference) {
    step = .cloud
    self.size = size
    welcoming = true
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
    var state = Onboarding.State(welcoming: welcoming)
    if welcoming { return state }
    state.childName = "Wren"
    state.path = Onboarding.Step.allCases.filter { $0 != .cloud && $0.rawValue <= step.rawValue }
    if step.rawValue > Onboarding.Step.listening.rawValue { state.authorization = .authorized }
    if step == .soundButtons { state.soundButtons = true }
    if step.rawValue > Onboarding.Step.cloud.rawValue { state.cloudSync = false }
    if step == .cloud {
      state.cloudSync = true
      state.cloudAccount = .signedOut
    }
    return state
  }
}

#Preview("Welcome") { OnboardingPreview(welcomeOn: Metrics.phone.reference) }
#Preview("iCloud") { OnboardingPreview(.cloud) }
#Preview("Name") { OnboardingPreview(.name) }
#Preview("Microphone") { OnboardingPreview(.listening) }
#Preview("What's ahead") { OnboardingPreview(.ahead) }
#Preview("Sound buttons") { OnboardingPreview(.soundButtons) }
#endif
