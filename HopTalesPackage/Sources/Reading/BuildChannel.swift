import StoreKit

enum BuildChannel {
  static func isPreRelease() async -> Bool {
    #if DEBUG
      return true
    #else
      guard case let .verified(transaction) = try? await AppTransaction.shared else { return false }
      return transaction.environment != .production
    #endif
  }
}
