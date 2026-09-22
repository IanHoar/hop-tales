import Foundation

/// Time of day across the traverse (`HANDOFF.md` §6). Boundaries crossfade over ~200pt of
/// progress.
public enum WorldStage: String, Hashable, Sendable, CaseIterable {
  case meadow
  case castle
  case dragon

  public init(progress: Double) {
    switch progress {
    case ..<650: self = .meadow
    case ..<1400: self = .castle
    default: self = .dragon
    }
  }

  public var skyAsset: String {
    switch self {
    case .meadow: "sky-day"
    case .castle: "sky-gold"
    case .dragon: "sky-dusk"
    }
  }
}

/// The world is six phone-widths long; a full story traverses it exactly once.
public enum WorldMetrics {
  public static let size = CGSize(width: 2340, height: 844)
  public static let traverse: Double = 1950
  /// Everything below this is hidden behind the word card on phone.
  public static let groundCrest: Double = 452
}
