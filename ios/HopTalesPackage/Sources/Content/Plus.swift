import Foundation

public enum Plus {
  public static let locksStories = false

  public static let freeLevel = 1

  public static func isLocked(
    _ story: Story,
    isPlus: Bool,
    locksStories: Bool = Plus.locksStories
  ) -> Bool {
    locksStories && !story.isFree && !isPlus
  }
}

public enum PlusPlan: String, CaseIterable, Hashable, Sendable {
  case monthly
  case yearly

  public static let appStoreGroup = "hop_tales_plus"
  public static let playProductID = "hop_tales_plus"
  public static let playTrialOfferID = "yearly-free-trial"

  public var appStoreProductID: String {
    switch self {
    case .monthly: "com.hoptales.plus.monthly"
    case .yearly: "com.hoptales.plus.yearly"
    }
  }

  public var playBasePlanID: String {
    switch self {
    case .monthly: "monthly"
    case .yearly: "yearly"
    }
  }

  public var playOfferID: String? {
    self == .yearly ? Self.playTrialOfferID : nil
  }

  public init?(appStoreProductID: String) {
    guard let plan = Self.allCases.first(where: { $0.appStoreProductID == appStoreProductID })
    else { return nil }
    self = plan
  }

  public init?(playProductID: String, basePlanID: String) {
    guard
      playProductID == Self.playProductID,
      let plan = Self.allCases.first(where: { $0.playBasePlanID == basePlanID })
    else { return nil }
    self = plan
  }
}
