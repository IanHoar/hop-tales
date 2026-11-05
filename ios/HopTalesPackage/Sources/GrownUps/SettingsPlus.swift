import ComposableArchitecture
import Content
import DesignSystem
import StoreKit
import SwiftUI
import World

extension Settings {
  @CasePathable
  public enum Subscription {
    case manageClosed
    case manageTapped
    case refundClosed
    case refundTapped
    case statusResolved(PlusStatus)
    case subscribeTapped
  }

  public enum GatedRequest: Hashable, Sendable {
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

  var body: some View {
    Group {
      if store.plusStatus.canSubscribe {
        PlusUpsell { store.send(.subscription(.subscribeTapped)) }
      } else {
        PlusMembership(store: store)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .settingsField()
  }
}

struct PlusUpsell: View {
  let unlock: () -> Void
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    VStack(spacing: 16) {
      meadow
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

  private var meadow: some View {
    GeometryReader { proxy in
      MeadowBackdrop(progress: 900, mood: Mood(sky: colorScheme == .dark ? .night : .day))
        .frame(width: proxy.size.width * 2, height: proxy.size.height * 2)
        .scaleEffect(0.5, anchor: .topLeading)
    }
      .overlay(alignment: .bottom) {
        HStack(alignment: .bottom, spacing: 18) {
          ForEach(Friend.starters, id: \.self) { friend in
            IdleFriend(friend, look: nil, height: 76, isPaused: true)
              .shadow(color: Paper.shadow, radius: 4, y: 3)
          }
        }
        .padding(.bottom, 14)
      }
      .frame(height: 150)
      .clipShape(.rect(cornerRadius: 14))
      .accessibilityHidden(true)
  }
}

struct PlusMembership: View {
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
      VStack(alignment: .leading, spacing: 10) {
        Button("Manage subscription", systemImage: "creditcard") {
          store.send(.subscription(.manageTapped))
        }
        if store.plusStatus.canRequestRefund {
          Button("Request a refund", systemImage: "arrow.uturn.backward.circle") {
            store.send(.subscription(.refundTapped))
          }
        }
      }
      .buttonStyle(.paperChip)
    }
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
