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
    OnboardingScreen(store: Store(initialState: state) { Onboarding() })
      .frame(width: size.width, height: size.height)
  }

  private var state: Onboarding.State {
    var state = Onboarding.State()
    state.childName = "Wren"
    state.path = Onboarding.Step.allCases.filter { $0 != .name && $0.rawValue <= step.rawValue }
    if step.rawValue > Onboarding.Step.listening.rawValue { state.authorization = .authorized }
    if step == .friend { state.startingFriend = .hare }
    if step == .accent {
      state.startingFriend = .bunny
      state.accent = .canadian
    }
    return state
  }
}

#Preview("Name") { OnboardingPreview(.name) }
#Preview("Microphone") { OnboardingPreview(.listening) }
#Preview("Starting friend") { OnboardingPreview(.friend) }
#Preview("Accent") { OnboardingPreview(.accent) }
#endif
