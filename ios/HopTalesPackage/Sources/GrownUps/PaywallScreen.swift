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

public struct PlusSubscribed: FeatureEventKey {
  public init() {}
}

public struct PlusWelcome: Equatable, Sendable {
  public var story: Story
  public var friend: Friend
  public var meetsFriend: Bool

  public init(story: Story, friend: Friend, meetsFriend: Bool) {
    self.story = story
    self.friend = friend
    self.meetsFriend = meetsFriend
  }
}

@Feature public struct Paywall {
  public init() {}

  public enum Work: Equatable, Sendable {
    case subscribing
    case restoring
  }

  public struct State: Identifiable {
    public var id = "paywall"
    public var offers = PaywallOffers.loading
    public var selected = PlusPlan.paywallOrder[0]
    public var work: Work?
    public var isPending = false
    public var isSubscribed = false
    public var foundNothingToRestore = false
    public var welcome: PlusWelcome?
    @StoreTaskID var storeRequest

    public init(welcome: PlusWelcome? = nil) {
      self.welcome = welcome
    }
  }

  public enum Action {
    case closeTapped
    case offersFailed
    case offersLoaded([PlusOffer])
    case planTapped(PlusPlan)
    case purchaseCompleted(PurchaseOutcome)
    case readTapped
    case restoreCompleted(Bool)
    case restoreTapped
    case subscribeTapped
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
        if let first = ordered.first, !ordered.contains(where: { $0.plan == state.selected }) {
          state.selected = first.plan
        }

      case let .planTapped(plan):
        guard state.work == nil else { break }
        state.selected = plan

      case .subscribeTapped:
        guard state.work == nil, case .loaded = state.offers else { break }
        state.work = .subscribing
        state.foundNothingToRestore = false
        let plan = state.selected
        store.addTask(id: state.storeRequest) {
          let outcome = (try? await purchases.purchase(plan)) ?? .failed
          try store.send(.purchaseCompleted(outcome))
          guard outcome == .purchased else { return }
          purchases.refresh()
          try store.post(PlusSubscribed())
        }

      case let .purchaseCompleted(outcome):
        state.work = nil
        switch outcome {
        case .purchased: state.isSubscribed = true
        case .pending: state.isPending = true
        case .cancelled, .failed: break
        }

      case .restoreTapped:
        guard state.work == nil else { break }
        state.work = .restoring
        state.foundNothingToRestore = false
        store.addTask(id: state.storeRequest) {
          let isPlus = (try? await purchases.restore()) ?? false
          try store.send(.restoreCompleted(isPlus))
          if isPlus { try store.post(PlusSubscribed()) }
        }

      case let .restoreCompleted(isPlus):
        state.work = nil
        state.isSubscribed = isPlus
        state.foundNothingToRestore = !isPlus

      case .closeTapped, .readTapped:
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
      if store.isSubscribed {
        GeometryReader { proxy in
          PaperConfetti(size: proxy.size, delay: 0.2)
        }
        .ignoresSafeArea()
      }
    }
    .animation(.easeInOut(duration: 0.35), value: store.isSubscribed)
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
    if store.isSubscribed {
      sheet(hugging: true) { PlusWelcomePage(welcome: store.welcome) { store.send($0) } }
        .transition(.scale(scale: 0.92).combined(with: .opacity))
    } else if store.isPending {
      sheet { pending }
    } else if case .unavailable = store.offers {
      sheet { unavailable }
    } else {
      sheet {
        VStack(spacing: 18) {
          PaywallPitch()
          plans
            .animation(.easeOut(duration: 0.3), value: store.offers)
          subscribeButton
          Spacer(minLength: 0)
          footer
        }
      }
    }
  }

  @ViewBuilder private var plans: some View {
    if case let .loaded(offers) = store.offers {
      PlanList(offers: offers, selected: store.selected) { store.send(.planTapped($0)) }
        .disabled(store.work != nil)
    } else {
      PlanList(offers: PlusOffer.samples, selected: store.selected) { _ in }
        .redacted(reason: .placeholder)
        .disabled(true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Finding the plans")
    }
  }

  private var isLoaded: Bool {
    if case .loaded = store.offers { return true }
    return false
  }

  private var subscribeButton: some View {
    Button { store.send(.subscribeTapped) } label: {
      if store.work == .subscribing {
        HStack(spacing: 10) {
          ProgressView()
            .tint(Paper.onRed)
          Text("Subscribing…")
        }
      } else {
        Text("Subscribe")
      }
    }
    .buttonStyle(.paper)
    .disabled(!isLoaded)
    .allowsHitTesting(store.work == nil)
    .animation(.easeInOut(duration: 0.2), value: store.work)
  }

  private func sheet(
    hugging: Bool = false,
    @ViewBuilder _ content: () -> some View
  ) -> some View {
    let content = content()
    return GeometryReader { proxy in
      let room = max(proxy.size.height - Self.headerHeight - 38, 0)
      ScrollView {
        header
        content
          .padding(24)
          .frame(maxWidth: .infinity, minHeight: hugging ? nil : room, alignment: .top)
          .clipShape(PaperSheet.shape)
          .background { PaperSheet() }
          .frame(maxWidth: 460)
          .padding(.horizontal, 12)
          .frame(minHeight: hugging ? room * 0.85 : nil)
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
        Button { store.send(.restoreTapped) } label: {
          if store.work == .restoring {
            HStack(spacing: 6) {
              ProgressView()
                .controlSize(.small)
              Text("Restoring…")
            }
          } else {
            Text("Restore purchases")
          }
        }
        .disabled(store.work != nil)
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
