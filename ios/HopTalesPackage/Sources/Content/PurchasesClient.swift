import Dependencies
import Foundation
import StoreKit
import Synchronization

public struct PlusTransaction: Hashable, Sendable {
  public var productID: String
  public var isVerified: Bool
  public var revocationDate: Date?
  public var expirationDate: Date?
  public var isFamilyShared: Bool

  public init(
    productID: String,
    isVerified: Bool = true,
    revocationDate: Date? = nil,
    expirationDate: Date? = nil,
    isFamilyShared: Bool = false
  ) {
    self.productID = productID
    self.isVerified = isVerified
    self.revocationDate = revocationDate
    self.expirationDate = expirationDate
    self.isFamilyShared = isFamilyShared
  }

  public var entitles: Bool {
    isVerified && revocationDate == nil && PlusPlan(appStoreProductID: productID) != nil
  }

  public static func isPlus(_ transactions: [PlusTransaction]) -> Bool {
    transactions.contains(where: \.entitles)
  }

  public static func nextCheck(_ transactions: [PlusTransaction], after now: Date) -> Date? {
    transactions
      .filter(\.entitles)
      .compactMap(\.expirationDate)
      .filter { $0 > now }
      .max()
  }
}

extension PlusTransaction {
  init(_ result: VerificationResult<Transaction>) {
    switch result {
    case let .verified(transaction):
      self.init(transaction, isVerified: true)
    case let .unverified(transaction, _):
      self.init(transaction, isVerified: false)
    }
  }

  init(_ transaction: Transaction, isVerified: Bool) {
    self.init(
      productID: transaction.productID,
      isVerified: isVerified,
      revocationDate: transaction.revocationDate,
      expirationDate: transaction.expirationDate,
      isFamilyShared: transaction.ownershipType == .familyShared
    )
  }
}

public struct PlusOffer: Hashable, Identifiable, Sendable {
  public var plan: PlusPlan
  public var price: String
  public var monthlyPrice: String?
  public var isFromAppStore: Bool

  public init(plan: PlusPlan, price: String, monthlyPrice: String? = nil, isFromAppStore: Bool) {
    self.plan = plan
    self.price = price
    self.monthlyPrice = monthlyPrice
    self.isFromAppStore = isFromAppStore
  }

  public var id: PlusPlan { plan }

  public static let samples = [
    PlusOffer(plan: .yearly, price: "$29.99", monthlyPrice: "$2.50", isFromAppStore: false),
    PlusOffer(plan: .monthly, price: "$4.99", isFromAppStore: false)
  ]

  public static func inPaywallOrder(_ offers: [PlusOffer]) -> [PlusOffer] {
    PlusPlan.paywallOrder.compactMap { plan in offers.first { $0.plan == plan } }
  }
}

extension PlusOffer {
  public init?(_ product: Product) {
    guard let plan = PlusPlan(appStoreProductID: product.id) else { return nil }
    let monthly = plan.months > 1
      ? (product.price / Decimal(plan.months)).formatted(product.priceFormatStyle)
      : nil
    self.init(
      plan: plan, price: product.displayPrice, monthlyPrice: monthly, isFromAppStore: true
    )
  }
}

public enum PurchaseOutcome: Hashable, Sendable {
  case purchased
  case pending
  case cancelled
  case failed

  public typealias StoreResult = Result<Product.PurchaseResult, any Error>

  public static func settling(_ result: StoreResult) async -> PurchaseOutcome {
    switch result {
    case let .success(.success(.verified(transaction))):
      await transaction.finish()
      return .purchased
    case .success(.success(.unverified)):
      return .failed
    case .success(.pending):
      return .pending
    case .success(.userCancelled):
      return .cancelled
    case .success, .failure:
      return .failed
    }
  }
}

public struct PurchasesUnavailable: Error {
  public init() {}
}

public struct PurchasesClient: Sendable {
  public var start: @Sendable () -> Void
  public var isPlus: @Sendable () -> AsyncStream<Bool>
  public var offers: @Sendable () async throws -> [PlusOffer]
  public var purchase: @Sendable (PlusPlan) async throws -> PurchaseOutcome
  public var restore: @Sendable () async throws -> Bool
  public var refresh: @Sendable () -> Void
  public var status: @Sendable () async -> PlusStatus?

  public init(
    start: @escaping @Sendable () -> Void,
    isPlus: @escaping @Sendable () -> AsyncStream<Bool>,
    offers: @escaping @Sendable () async throws -> [PlusOffer] = { throw PurchasesUnavailable() },
    purchase: @escaping @Sendable (PlusPlan) async throws -> PurchaseOutcome = { _ in .failed },
    restore: @escaping @Sendable () async throws -> Bool = { false },
    refresh: @escaping @Sendable () -> Void = {},
    status: @escaping @Sendable () async -> PlusStatus? = { nil }
  ) {
    self.start = start
    self.isPlus = isPlus
    self.offers = offers
    self.purchase = purchase
    self.restore = restore
    self.refresh = refresh
    self.status = status
  }
}

extension PurchasesClient: DependencyKey {
  public static let liveValue: PurchasesClient = {
    let entitlement = StoreEntitlement()
    return PurchasesClient(
      start: { entitlement.start() },
      isPlus: { entitlement.stream() },
      offers: {
        let ids = PlusPlan.paywallOrder.map(\.appStoreProductID)
        let offers = try await Product.products(for: ids).compactMap(PlusOffer.init)
        guard !offers.isEmpty else { throw PurchasesUnavailable() }
        return PlusOffer.inPaywallOrder(offers)
      },
      purchase: { plan in
        guard let product = try await Product.products(for: [plan.appStoreProductID]).first
        else { throw PurchasesUnavailable() }
        let result: Result<Product.PurchaseResult, any Error>
        do {
          result = .success(try await product.purchase())
        } catch {
          result = .failure(error)
        }
        return await PurchaseOutcome.settling(result)
      },
      restore: {
        try await AppStore.sync()
        var current: [PlusTransaction] = []
        for await result in Transaction.currentEntitlements {
          current.append(PlusTransaction(result))
        }
        entitlement.refresh()
        return PlusTransaction.isPlus(current)
      },
      refresh: { entitlement.refresh() },
      status: {
        let ids = PlusPlan.paywallOrder.map(\.appStoreProductID)
        guard
          let products = try? await Product.products(for: ids),
          let subscription = products.first(where: { $0.subscription != nil })?.subscription,
          let statuses = try? await subscription.status
        else { return nil }
        return PlusStatus.of(statuses.map(PlusRenewal.init))
      }
    )
  }()

  public static let testValue = fixed(false)

  public static let previewValue = fake()

  public static func fixed(_ isPlus: Bool) -> PurchasesClient {
    PurchasesClient(
      start: {},
      isPlus: {
        AsyncStream { continuation in
          continuation.yield(isPlus)
          continuation.finish()
        }
      }
    )
  }

  public static func streaming(_ values: AsyncStream<Bool>) -> PurchasesClient {
    PurchasesClient(start: {}, isPlus: { values })
  }

  public static func fake(
    isPlus: Bool = false,
    offers: [PlusOffer]? = PlusOffer.samples,
    outcome: PurchaseOutcome = .purchased,
    restores: Bool = false,
    status: PlusStatus? = nil
  ) -> PurchasesClient {
    let store = FakeStore(isPlus: isPlus)
    return PurchasesClient(
      start: {},
      isPlus: { store.stream() },
      offers: {
        guard let offers else { throw PurchasesUnavailable() }
        return offers
      },
      purchase: { _ in
        if outcome == .purchased { store.own() }
        return outcome
      },
      restore: {
        if restores { store.own() }
        store.refresh()
        return store.isPlus
      },
      refresh: { store.refresh() },
      status: { status }
    )
  }
}

final class FakeStore: Sendable {
  private struct State {
    var isPlus: Bool
    var owns = false
    var subscribers: [UUID: AsyncStream<Bool>.Continuation] = [:]
  }

  private let state: Mutex<State>

  init(isPlus: Bool) {
    state = Mutex(State(isPlus: isPlus))
  }

  var isPlus: Bool { state.withLock(\.isPlus) }

  func stream() -> AsyncStream<Bool> {
    let id = UUID()
    let (stream, continuation) = AsyncStream.makeStream(
      of: Bool.self,
      bufferingPolicy: .bufferingNewest(1)
    )
    continuation.onTermination = { [weak self] _ in
      self?.state.withLock { _ = $0.subscribers.removeValue(forKey: id) }
    }
    state.withLock { state in
      state.subscribers[id] = continuation
      continuation.yield(state.isPlus)
    }
    return stream
  }

  func own() {
    state.withLock { $0.owns = true }
  }

  func refresh() {
    if state.withLock(\.owns) { publish(true) }
  }

  func publish(_ isPlus: Bool) {
    state.withLock { state in
      guard state.isPlus != isPlus else { return }
      state.isPlus = isPlus
      for subscriber in state.subscribers.values { subscriber.yield(isPlus) }
    }
  }
}

final class StoreEntitlement: Sendable {
  private struct State {
    var isPlus: Bool?
    var listener: Task<Void, Never>?
    var change: AsyncStream<Void>.Continuation?
    var subscribers: [UUID: AsyncStream<Bool>.Continuation] = [:]
  }

  private let state = Mutex(State())

  func start() {
    state.withLock { state in
      guard state.listener == nil else { return }
      state.listener = Task.detached { [weak self] in
        await self?.listen()
      }
    }
  }

  func refresh() {
    start()
    state.withLock { _ = $0.change?.yield() }
  }

  func stream() -> AsyncStream<Bool> {
    start()
    let id = UUID()
    let (stream, continuation) = AsyncStream.makeStream(
      of: Bool.self,
      bufferingPolicy: .bufferingNewest(1)
    )
    continuation.onTermination = { [weak self] _ in
      self?.state.withLock { _ = $0.subscribers.removeValue(forKey: id) }
    }
    state.withLock { state in
      state.subscribers[id] = continuation
      if let isPlus = state.isPlus { continuation.yield(isPlus) }
    }
    return stream
  }

  private func publish(_ isPlus: Bool) {
    state.withLock { state in
      guard state.isPlus != isPlus else { return }
      state.isPlus = isPlus
      for subscriber in state.subscribers.values { subscriber.yield(isPlus) }
    }
  }

  private func listen() async {
    let (changes, change) = AsyncStream.makeStream(
      of: Void.self,
      bufferingPolicy: .bufferingNewest(1)
    )
    state.withLock { $0.change = change }
    let transactions = Task {
      for await update in Transaction.updates {
        if case let .verified(transaction) = update { await transaction.finish() }
        change.yield()
      }
    }
    let statuses = Task {
      for await _ in Product.SubscriptionInfo.Status.updates { change.yield() }
    }
    var expiry: Task<Void, Never>?
    defer {
      state.withLock { $0.change = nil }
      transactions.cancel()
      statuses.cancel()
      expiry?.cancel()
    }
    change.yield()
    for await _ in changes {
      var current: [PlusTransaction] = []
      for await result in Transaction.currentEntitlements {
        current.append(PlusTransaction(result))
      }
      publish(PlusTransaction.isPlus(current))
      expiry?.cancel()
      expiry = PlusTransaction.nextCheck(current, after: Date()).map { date in
        Task {
          try? await Task.sleep(for: .seconds(date.timeIntervalSinceNow + 1))
          guard !Task.isCancelled else { return }
          change.yield()
        }
      }
    }
  }
}
