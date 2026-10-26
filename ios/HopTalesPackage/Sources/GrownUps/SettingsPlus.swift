import ComposableArchitecture
import Content
import DesignSystem
import StoreKit
import SwiftUI

extension Settings {
  @CasePathable
  public enum Subscription {
    case manageClosed
    case manageTapped
    case refundClosed
    case refundTapped
    case restoreTapped
    case restored(Bool)
    case statusResolved(PlusStatus)
    case subscribeTapped
  }

  public enum GatedRequest: Hashable, Sendable {
    case restore
    case manage
    case refund
  }

  func subscription(_ action: Subscription, _ state: inout State) {
    switch action {
    case .manageClosed:
      state.isManagingSubscription = false
      reloadStatus()
    case .manageTapped:
      ask(.manage, &state)
    case .refundClosed:
      state.isRequestingRefund = false
      reloadStatus()
    case .refundTapped:
      ask(.refund, &state)
    case .restoreTapped:
      ask(.restore, &state)
    case let .restored(isPlus):
      state.foundNothingToRestore = !isPlus
      reloadStatus()
    case let .statusResolved(status):
      state.plusStatus = status
    case .subscribeTapped:
      state.grownUp = GrownUpPaywall.State(seed: gateSeed.draw())
    }
  }

  func ask(_ request: GatedRequest, _ state: inout State) {
    state.gatedRequest = request
    state.gate = ParentGate.State(seed: gateSeed.draw())
  }

  func grant(_ state: inout State) {
    let request = state.gatedRequest
    state.gate = nil
    state.gatedRequest = nil
    switch request {
    case .restore:
      state.foundNothingToRestore = false
      restore()
    case .manage:
      state.isManagingSubscription = true
    case .refund:
      state.isRequestingRefund = state.plusStatus.canRequestRefund
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
  @Environment(\.locale) private var locale
  @Environment(\.timeZone) private var timeZone

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      VStack(alignment: .leading, spacing: 4) {
        Text(store.plusStatus.line(locale: locale, timeZone: timeZone))
          .font(Typography.display(20))
          .foregroundStyle(Paper.ink)
        if let detail = store.plusStatus.detail {
          Text(detail)
            .font(Typography.ui(15, weight: .medium))
            .foregroundStyle(Paper.muted)
        }
      }
      .fixedSize(horizontal: false, vertical: true)
      VStack(alignment: .leading, spacing: 4) {
        Text(PlusStatus.gives)
        Text(PlusStatus.rhythm)
      }
      .font(Typography.ui(15))
      .foregroundStyle(Paper.muted)
      .fixedSize(horizontal: false, vertical: true)
      if store.plusStatus.canSubscribe {
        Button("Subscribe") { store.send(.subscription(.subscribeTapped)) }
          .buttonStyle(.paper)
      }
      VStack(alignment: .leading, spacing: 10) {
        Button("Restore purchases", systemImage: "arrow.clockwise") {
          store.send(.subscription(.restoreTapped))
        }
        if store.plusStatus.canManage {
          Button("Manage subscription", systemImage: "creditcard") {
            store.send(.subscription(.manageTapped))
          }
        }
        if store.plusStatus.canRequestRefund {
          Button("Request a refund", systemImage: "arrow.uturn.backward.circle") {
            store.send(.subscription(.refundTapped))
          }
        }
      }
      .buttonStyle(.paperChip)
      if store.foundNothingToRestore {
        Text("There's no Hop Tales Plus subscription to restore on this Apple Account.")
          .font(Typography.ui(14, weight: .medium))
          .foregroundStyle(Paper.muted)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .settingsField()
  }
}

extension View {
  @ViewBuilder
  func subscriptionSheets(_ store: StoreOf<Settings>) -> some View {
    let managing = manageSubscriptionsSheet(
      isPresented: Binding(
        get: { store.isManagingSubscription },
        set: { if !$0 { store.send(.subscription(.manageClosed)) } }
      )
    )
    if let transaction = store.plusStatus.refundableTransactionID {
      managing.refundRequestSheet(
        for: transaction,
        isPresented: Binding(
          get: { store.isRequestingRefund },
          set: { if !$0 { store.send(.subscription(.refundClosed)) } }
        )
      )
    } else {
      managing
    }
  }
}
