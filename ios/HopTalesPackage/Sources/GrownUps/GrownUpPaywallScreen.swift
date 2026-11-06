import ComposableArchitecture
import SwiftUI

@Feature public struct GrownUpPaywall {
  public init() {}

  public struct State: Identifiable {
    public var id = "grown-up-paywall"
    public var gate: ParentGate.State?
    public var paywall: Paywall.State?
    public var welcome: PlusWelcome?

    public init(seed: UInt64, welcome: PlusWelcome? = nil) {
      gate = ParentGate.State(seed: seed)
      self.welcome = welcome
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
        state.paywall = Paywall.State(welcome: state.welcome)
      case .gate(.closeTapped), .paywall(.closeTapped), .paywall(.readTapped):
        store.addTask { try store.dismiss() }
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
  @Bindable var store: StoreOf<GrownUpPaywall>

  public init(store: StoreOf<GrownUpPaywall>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack {
      Group {
        if let gate = store.scope(\.gate) {
          ParentGateScreen(store: gate)
        }
      }
      .toolbar(.hidden, for: .navigationBar)
      .navigationDestination(item: $store.scope(\.paywall)) { paywall in
        PaywallScreen(store: paywall)
          .toolbar(.hidden, for: .navigationBar)
          .navigationBarBackButtonHidden()
      }
    }
  }
}
