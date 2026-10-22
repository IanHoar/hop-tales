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

public struct PurchasesClient: Sendable {
  public var start: @Sendable () -> Void
  public var isPlus: @Sendable () -> AsyncStream<Bool>

  public init(
    start: @escaping @Sendable () -> Void,
    isPlus: @escaping @Sendable () -> AsyncStream<Bool>
  ) {
    self.start = start
    self.isPlus = isPlus
  }
}

extension PurchasesClient: DependencyKey {
  public static let liveValue: PurchasesClient = {
    let entitlement = StoreEntitlement()
    return PurchasesClient(
      start: { entitlement.start() },
      isPlus: { entitlement.stream() }
    )
  }()

  public static let testValue = fixed(false)

  public static let previewValue = fixed(false)

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
}

final class StoreEntitlement: Sendable {
  private struct State {
    var isPlus: Bool?
    var listener: Task<Void, Never>?
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
