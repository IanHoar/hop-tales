import ComposableArchitecture2
import SwiftUI

@Feature public struct GrownUpPaywall {
  public init() {}

  public struct State: Identifiable {
    public var id = "grown-up-paywall"
    public var isOnboarding: Bool
    public var gate: ParentGate.State?
    public var paywall: Paywall.State?

    public init(seed: UInt64, isOnboarding: Bool = false) {
      self.isOnboarding = isOnboarding
      gate = ParentGate.State(seed: seed)
    }
  }

  public enum Action {
    case gate(ParentGate.Action)
    case paywall(Paywall.Action)
  }

  public var body: some Feature {
    Update { state, action in
      switch action {
      case .gate(.passed):
        state.gate = nil
        state.paywall = Paywall.State(isOnboarding: state.isOnboarding)
      case .gate, .paywall:
        break
      }
    }
    .ifLet(\.gate) {
      ParentGate()
    }
    .ifLet(\.paywall) {
      Paywall()
    }
  }
}

public struct GrownUpPaywallScreen: View {
  let store: StoreOf<GrownUpPaywall>

  public init(store: StoreOf<GrownUpPaywall>) {
    self.store = store
  }

  public var body: some View {
    if let paywall = store.scope(\.paywall) {
      PaywallScreen(store: paywall)
    } else if let gate = store.scope(\.gate) {
      ParentGateScreen(store: gate)
    }
  }
}
