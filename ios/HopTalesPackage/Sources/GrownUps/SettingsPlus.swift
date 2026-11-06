import ComposableArchitecture
import Content
import DesignSystem
import StoreKit
import SwiftUI
import World

extension Settings {
  @CasePathable
  public enum Subscription {
    case manageTapped
    case statusResolved(PlusStatus)
    case subscribeTapped
  }

  public enum GatedRequest: Hashable, Sendable {
    case manage
  }

  func subscription(_ action: Subscription, _ state: inout State) {
    switch action {
    case .manageTapped:
      ask(.manage, &state)
    case let .statusResolved(status):
      state.plusStatus = status
    case .subscribeTapped:
      state.grownUp = GrownUpPaywall.State(seed: gateSeed.draw())
    }
  }

  func ask(_ request: GatedRequest, _ state: inout State) {
    gatedRequest = request
    state.gate = ParentGate.State(seed: gateSeed.draw())
  }

  func grant(_ state: inout State) {
    let request = gatedRequest
    state.gate = nil
    gatedRequest = nil
    switch request {
    case .manage:
      state.isManagingSubscription = true
    case nil:
      break
    }
  }

  nonisolated static func currentStatus(_ purchases: PurchasesClient) async -> PlusStatus {
    var isPlus = false
    for await value in purchases.isPlus() {
      isPlus = value
      break
    }
    return PlusStatus.resolved(isPlus: isPlus, details: await purchases.status())
  }

}

struct PlusRow: View {
  let store: StoreOf<Settings>

  var body: some View {
    if store.plusStatus.canSubscribe {
      PlusUpsell { store.send(.subscription(.subscribeTapped)) }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .settingsField()
    } else {
      PlusMembership(store: store)
    }
  }
}

struct PlusUpsell: View {
  let unlock: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      PlusTaste()
      VStack(spacing: 4) {
        Text("Hop Tales Plus")
          .font(Typography.display(28))
          .foregroundStyle(Paper.ink)
        Text("Unlock more stories and characters.")
          .font(Typography.ui(16, weight: .medium))
          .foregroundStyle(Paper.muted)
      }
      .multilineTextAlignment(.center)
      .fixedSize(horizontal: false, vertical: true)
      Button(action: unlock) {
        Label("Unlock now", systemImage: "lock.fill")
      }
      .buttonStyle(.paper)
    }
  }
}

struct PlusMembership: View {
  let store: StoreOf<Settings>
  @Environment(\.locale) private var locale
  @Environment(\.timeZone) private var timeZone

  var body: some View {
    VStack(spacing: 8) {
      Button {
        store.send(.subscription(.manageTapped))
      } label: {
        Label("Manage subscription", systemImage: "creditcard")
      }
      .buttonStyle(.paperQuiet)
      VStack(spacing: 2) {
        Text(store.plusStatus.line(locale: locale, timeZone: timeZone))
          .font(Typography.ui(14, weight: .semibold))
          .foregroundStyle(Paper.muted)
        if let detail = store.plusStatus.detail {
          Text(detail)
            .font(Typography.ui(14, weight: .medium))
            .foregroundStyle(Paper.muted)
        }
      }
      .multilineTextAlignment(.center)
      .fixedSize(horizontal: false, vertical: true)
    }
  }
}

extension View {
  @ViewBuilder
  func subscriptionSheets(_ store: StoreOf<Settings>) -> some View {
    manageSubscriptionsSheet(isPresented: Bindable(store).isManagingSubscription)
  }
}
