import ComposableArchitecture
import Content
import Dependencies
import DesignSystem
import StoreKit
import SwiftUI
import World

public enum PaywallOffers: Hashable, Sendable {
  case loading
  case loaded([PlusOffer])
  case unavailable
}

@Feature public struct Paywall {
  public init() {}

  public struct State: Identifiable {
    public var id = "paywall"
    public var offers = PaywallOffers.loading
    public var isPending = false
    public var foundNothingToRestore = false

    public init() {}

    var usesAppStoreView: Bool {
      guard case let .loaded(offers) = offers else { return false }
      return offers.allSatisfy(\.isFromAppStore)
    }
  }

  public enum Action {
    case closeTapped
    case offersFailed
    case offersLoaded([PlusOffer])
    case planTapped(PlusPlan)
    case nothingToRestore
    case purchaseCompleted(PurchaseOutcome)
    case restoreTapped
    case subscribed
  }

  @Dependency(PurchasesClient.self) var purchases

  public var body: some Feature {
    Update { state, action in
      switch action {
      case .offersFailed:
        state.offers = .unavailable

      case let .offersLoaded(offers):
        let ordered = PlusOffer.inPaywallOrder(offers)
        state.offers = ordered.isEmpty ? .unavailable : .loaded(ordered)

      case let .planTapped(plan):
        state.foundNothingToRestore = false
        store.addTask {
          let outcome = (try? await purchases.purchase(plan)) ?? .failed
          try store.send(.purchaseCompleted(outcome))
          if outcome == .purchased { try store.send(.subscribed) }
        }

      case let .purchaseCompleted(outcome):
        switch outcome {
        case .purchased:
          purchases.refresh()
        case .pending:
          state.isPending = true
        case .cancelled, .failed:
          break
        }

      case .nothingToRestore:
        state.foundNothingToRestore = true

      case .restoreTapped:
        state.foundNothingToRestore = false
        store.addTask {
          let isPlus = (try? await purchases.restore()) ?? false
          try store.send(isPlus ? .subscribed : .nothingToRestore)
        }

      case .closeTapped, .subscribed:
        break
      }
    }
    .onMount { _ in
      store.addTask {
        do {
          let offers = try await purchases.offers()
          try store.send(.offersLoaded(offers))
        } catch is CancellationError {
        } catch {
          try store.send(.offersFailed)
        }
      }
    }
  }
}

public struct PaywallScreen: View {
  let store: StoreOf<Paywall>
  @Environment(\.colorScheme) private var colorScheme

  public init(store: StoreOf<Paywall>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      MeadowBackdrop(progress: 900, mood: Mood(sky: colorScheme == .dark ? .night : .day))
        .ignoresSafeArea()
        .accessibilityHidden(true)
      VStack(spacing: 0) {
        header
        content
      }
    }
  }

  private var header: some View {
    HStack(spacing: 12) {
      Spacer()
      Button("Close") { store.send(.closeTapped) }
        .font(Typography.display(17))
        .foregroundStyle(Paper.ink)
        .padding(.horizontal, 16)
        .frame(height: 40)
        .paperChip(Capsule(), rim: 3)
        .buttonStyle(.plain)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
  }

  @ViewBuilder private var content: some View {
    if store.isPending {
      sheet { pending }
    } else {
      switch store.offers {
      case .loading:
        sheet { loading }
      case .unavailable:
        sheet { unavailable }
      case let .loaded(offers):
        if store.usesAppStoreView {
          appStore
        } else {
          sheet {
            VStack(spacing: 18) {
              PaywallPitch()
              PlanList(offers: offers) { store.send(.planTapped($0)) }
              Spacer(minLength: 0)
              footer
            }
          }
        }
      }
    }
  }

  private var appStore: some View {
    SubscriptionStoreView(productIDs: PlusPlan.paywallOrder.map(\.appStoreProductID)) {
      PaywallPitch()
        .padding(24)
        .frame(maxWidth: .infinity)
        .background { PaperSheet() }
        .frame(maxWidth: 460)
        .padding(.horizontal, 20)
    }
    .subscriptionStoreControlStyle(PaperPlansStyle(footer: footer))
    .subscriptionStoreControlBackground(Paper.paper)
    .storeButton(.hidden, for: .cancellation, .policies, .restorePurchases, .redeemCode, .signIn)
    .containerBackground(Color.clear, for: .subscriptionStoreFullHeight)
    .onInAppPurchaseCompletion { _, result in
      let outcome = await PurchaseOutcome.settling(result)
      store.send(.purchaseCompleted(outcome))
    }
  }

  private func sheet(@ViewBuilder _ content: () -> some View) -> some View {
    let content = content()
    return GeometryReader { proxy in
      ScrollView {
        content
          .padding(24)
          .frame(maxWidth: .infinity, minHeight: max(proxy.size.height - 38, 0), alignment: .top)
          .background { PaperSheet() }
          .frame(maxWidth: 460)
          .padding(.horizontal, 20)
          .padding(.top, 8)
          .padding(.bottom, 30)
          .frame(maxWidth: .infinity)
      }
    }
  }

  private var footer: some View {
    VStack(spacing: 4) {
      Text(Self.disclosure)
        .font(Typography.ui(11))
        .foregroundStyle(Paper.muted)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
      if store.foundNothingToRestore {
        Text("There's no Hop Tales Plus subscription to restore on this Apple Account.")
          .font(Typography.ui(12, weight: .medium))
          .foregroundStyle(Paper.ink)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }
      HStack(spacing: 16) {
        Button("Restore purchases") { store.send(.restoreTapped) }
          .fontWeight(.semibold)
          .foregroundStyle(Paper.ink)
        Link("Terms of Use", destination: PlusLinks.terms)
          .underline()
        Link("Privacy Policy", destination: PlusLinks.privacy)
          .underline()
      }
      .buttonStyle(.plain)
      .font(Typography.ui(12, weight: .medium))
      .foregroundStyle(Paper.muted)
      .frame(minHeight: 44)
    }
    .frame(maxWidth: 460)
  }

  static let disclosure = """
    Hop Tales Plus renews automatically until you cancel. Payment is charged to your Apple \
    Account, and each plan renews at the same price unless you cancel at least 24 hours before \
    the period ends. Cancel any time in your App Store settings.
    """

  private var loading: some View {
    VStack(spacing: 14) {
      PaywallTitle()
      ProgressView()
        .tint(Paper.muted)
      Text("Finding the plans…")
        .font(Typography.ui(16, weight: .medium))
        .foregroundStyle(Paper.muted)
    }
  }

  private var unavailable: some View {
    VStack(spacing: 14) {
      Text("The store isn't answering")
        .font(Typography.display(26))
        .foregroundStyle(Paper.ink)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityAddTraits(.isHeader)
      Text(
        "We couldn't load the plans from the App Store just now. Please try again later. "
          + "Every Level 1 story stays free to read."
      )
      .font(Typography.ui(17, weight: .medium))
      .foregroundStyle(Paper.muted)
      .multilineTextAlignment(.center)
      .fixedSize(horizontal: false, vertical: true)
      leaveButton
    }
  }

  private var pending: some View {
    VStack(spacing: 14) {
      Text("Waiting for the store")
        .font(Typography.display(26))
        .foregroundStyle(Paper.ink)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityAddTraits(.isHeader)
      Text(
        "Your purchase is waiting to go through. Every story opens as soon as it does, "
          + "so you can close this now."
      )
      .font(Typography.ui(17, weight: .medium))
      .foregroundStyle(Paper.muted)
      .multilineTextAlignment(.center)
      .fixedSize(horizontal: false, vertical: true)
      leaveButton
    }
  }

  private var leaveButton: some View {
    Button("Back to stories") { store.send(.closeTapped) }
      .buttonStyle(.paperQuiet)
      .padding(.top, 6)
  }
}

#if DEBUG
struct PaywallPreview: View {
  var offers = PaywallOffers.loaded(PlusOffer.samples)
  var isPending = false

  var body: some View {
    PaywallScreen(
      store: Store(initialState: state) {
        Paywall()
          .dependency(PurchasesClient.fake(offers: loaded))
      }
    )
      .frame(width: Metrics.phone.reference.width, height: Metrics.phone.reference.height)
  }

  private var loaded: [PlusOffer]? {
    guard case let .loaded(offers) = offers else { return nil }
    return offers
  }

  private var state: Paywall.State {
    var state = Paywall.State()
    state.offers = offers
    state.isPending = isPending
    return state
  }
}

#Preview("Paywall") { PaywallPreview() }
#Preview("Paywall, store unavailable") { PaywallPreview(offers: .unavailable) }
#Preview("Paywall, waiting for the store") { PaywallPreview(isPending: true) }
#endif
