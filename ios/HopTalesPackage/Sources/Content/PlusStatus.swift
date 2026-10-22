import Foundation
import StoreKit

public struct PlusStatus: Hashable, Sendable {
  public enum Kind: Hashable, Sendable {
    case free
    case plus
    case renews(Date?)
    case ends(Date?)
    case familyShared
    case paymentProblem
    case pending
  }

  public var kind: Kind
  public var refundableTransactionID: UInt64?

  public init(_ kind: Kind, refundableTransactionID: UInt64? = nil) {
    self.kind = kind
    self.refundableTransactionID = refundableTransactionID
  }

  public static let free = PlusStatus(.free)

  public static let rhythm = "A new story every month, and something new each season."

  public static let gives = "Plus opens every story above Level 1."

  public static func resolved(isPlus: Bool, details: PlusStatus?) -> PlusStatus {
    switch (isPlus, details?.kind) {
    case (true, nil), (true, .free?): PlusStatus(.plus)
    case (false, nil): .free
    case let (_, kind?): PlusStatus(kind, refundableTransactionID: details?.refundableTransactionID)
    }
  }

  public var canSubscribe: Bool { kind == .free }

  public var canManage: Bool { kind != .free }

  public var canRequestRefund: Bool { refundableTransactionID != nil }

  public func line(locale: Locale = .current, timeZone: TimeZone = .current) -> String {
    switch kind {
    case .free: "Free: the Level 1 stories"
    case .plus: "Plus: every story"
    case let .renews(date?): "Plus, renews \(Self.day(date, locale: locale, timeZone: timeZone))"
    case .renews(nil): "Plus, renews automatically"
    case let .ends(date?): "Plus, ends \(Self.day(date, locale: locale, timeZone: timeZone))"
    case .ends(nil): "Plus, ends at the end of this period"
    case .familyShared: "Plus, shared by your family"
    case .paymentProblem: "There's a problem with your payment"
    case .pending: "Waiting for your payment to go through"
    }
  }

  public var detail: String? {
    switch kind {
    case .paymentProblem: "Check your payment details under Manage subscription."
    case .pending: "Every story opens as soon as it does."
    case .free, .plus, .renews, .ends, .familyShared: nil
    }
  }

  static func day(_ date: Date, locale: Locale, timeZone: TimeZone) -> String {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let style = Date.VerbatimFormatStyle(
      format: "\(day: .defaultDigits) \(month: .wide)",
      locale: locale,
      timeZone: timeZone,
      calendar: calendar
    )
    return date.formatted(style)
  }
}

public struct PlusRenewal: Hashable, Sendable {
  public enum State: Hashable, Sendable {
    case subscribed
    case inGracePeriod
    case inBillingRetry
    case expired
    case revoked
  }

  public var state: State
  public var transactionID: UInt64
  public var productID: String
  public var isVerified: Bool
  public var willAutoRenew: Bool
  public var periodEnds: Date?
  public var isFamilyShared: Bool

  public init(
    state: State,
    transactionID: UInt64,
    productID: String,
    isVerified: Bool = true,
    willAutoRenew: Bool = true,
    periodEnds: Date? = nil,
    isFamilyShared: Bool = false
  ) {
    self.state = state
    self.transactionID = transactionID
    self.productID = productID
    self.isVerified = isVerified
    self.willAutoRenew = willAutoRenew
    self.periodEnds = periodEnds
    self.isFamilyShared = isFamilyShared
  }

  var isTroubled: Bool { state == .inGracePeriod || state == .inBillingRetry }
}

extension PlusStatus {
  public static func of(_ renewals: [PlusRenewal]) -> PlusStatus? {
    let plus = renewals.filter { $0.isVerified && PlusPlan(appStoreProductID: $0.productID) != nil }
    guard !plus.isEmpty else { return nil }
    let own = plus.filter { !$0.isFamilyShared }
    if let active = own.first(where: { $0.state == .subscribed }) {
      let kind: Kind = active.willAutoRenew ? .renews(active.periodEnds) : .ends(active.periodEnds)
      return PlusStatus(kind, refundableTransactionID: active.transactionID)
    }
    if let troubled = own.first(where: \.isTroubled) {
      return PlusStatus(.paymentProblem, refundableTransactionID: troubled.transactionID)
    }
    if plus.contains(where: { $0.state == .subscribed || $0.state == .inGracePeriod }) {
      return PlusStatus(.familyShared)
    }
    return .free
  }
}

extension PlusRenewal {
  init(_ status: Product.SubscriptionInfo.Status) {
    let transaction: Transaction
    var isVerified: Bool
    switch status.transaction {
    case let .verified(verified):
      transaction = verified
      isVerified = true
    case let .unverified(unverified, _):
      transaction = unverified
      isVerified = false
    }
    var willAutoRenew = false
    switch status.renewalInfo {
    case let .verified(info):
      willAutoRenew = info.willAutoRenew
    case .unverified:
      isVerified = false
    }
    self.init(
      state: State(status.state),
      transactionID: transaction.id,
      productID: transaction.productID,
      isVerified: isVerified,
      willAutoRenew: willAutoRenew,
      periodEnds: transaction.expirationDate,
      isFamilyShared: transaction.ownershipType == .familyShared
    )
  }
}

extension PlusRenewal.State {
  init(_ state: Product.SubscriptionInfo.RenewalState) {
    switch state {
    case .subscribed: self = .subscribed
    case .inGracePeriod: self = .inGracePeriod
    case .inBillingRetryPeriod: self = .inBillingRetry
    case .revoked: self = .revoked
    default: self = .expired
    }
  }
}
