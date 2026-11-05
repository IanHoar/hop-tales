import ComposableArchitecture
import Content
import Dependencies
import DesignSystem
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
  @Dependency(\.continuousClock) var clock

  static let placeholderSeconds = 1.5

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
        let fetch = purchases.offers
        do {
          async let offers = fetch()
          try await clock.sleep(for: .seconds(Self.placeholderSeconds))
          try store.send(.offersLoaded(try await offers))
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
      content
    }
  }

  static let headerHeight: CGFloat = 64

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
    .frame(height: Self.headerHeight)
  }

  @ViewBuilder private var content: some View {
    if store.isPending {
      sheet { pending }
    } else if case .unavailable = store.offers {
      sheet { unavailable }
    } else {
      sheet {
        VStack(spacing: 18) {
          PaywallPitch()
          plans
            .animation(.easeOut(duration: 0.3), value: store.offers)
          Spacer(minLength: 0)
          footer
        }
      }
    }
  }

  @ViewBuilder private var plans: some View {
    if case let .loaded(offers) = store.offers {
      PlanList(offers: offers) { store.send(.planTapped($0)) }
    } else {
      PlanList(offers: PlusOffer.samples) { _ in }
        .redacted(reason: .placeholder)
        .disabled(true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Finding the plans")
    }
  }

  private func sheet(@ViewBuilder _ content: () -> some View) -> some View {
    let content = content()
    return GeometryReader { proxy in
      ScrollView {
        header
        content
          .padding(24)
          .frame(
            maxWidth: .infinity,
            minHeight: max(proxy.size.height - Self.headerHeight - 38, 0),
            alignment: .top
          )
          .clipShape(PaperSheet.shape)
          .background { PaperSheet() }
          .frame(maxWidth: 460)
          .padding(.horizontal, 12)
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
