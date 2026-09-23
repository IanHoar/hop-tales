import ComposableArchitecture2
import DesignSystem
import SwiftUI

@Feature public struct GrownUps {
  public init() {}

  public struct State {
    public var gate: ParentGate.State
    public var settings: Settings.State?

    public init(question: GateQuestion) {
      gate = ParentGate.State(question: question)
    }
  }

  public enum Action {
    case gate(ParentGate.Action)
    case settings(Settings.Action)
  }

  public var body: some Feature {
    Features {
      Update { state, action in
        switch action {
        case .gate(.unlocked):
          state.settings = Settings.State()
        case .gate, .settings:
          break
        }
      }
      Scope(\.gate) {
        ParentGate()
      }
    }
    .ifLet(\.settings) {
      Settings()
    }
  }
}

public struct GrownUpsScreen: View {
  let store: StoreOf<GrownUps>

  public init(store: StoreOf<GrownUps>) {
    self.store = store
  }

  public var body: some View {
    Group {
      if let settings = store.scope(\.settings) {
        SettingsScreen(store: settings)
          .transition(.move(edge: .trailing).combined(with: .opacity))
      } else {
        ParentGateScreen(store: store.scope(\.gate))
          .transition(.opacity)
      }
    }
    .animation(.easeInOut(duration: 0.25), value: store.settings == nil)
    .tint(Palette.ink)
  }
}
