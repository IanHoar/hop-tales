import Foundation

public enum Friend: String, Codable, CaseIterable, Hashable, Sendable {
  case bunny
  case hare
  case frog
  case crow
  case cat
  case crab
  case grasshopper

  public static let starters: [Friend] = [.bunny, .hare, .frog]

  public var name: String {
    switch self {
    case .bunny: "Bramble"
    case .hare: "Hare"
    case .frog: "Puddle"
    case .crow: "Button"
    case .cat: "Marmalade"
    case .crab: "Nipper"
    case .grasshopper: "Sprig"
    }
  }

  public var level: Int { (Self.allCases.firstIndex(of: self) ?? 0) + 1 }

  public var stage: String {
    switch self {
    case .bunny: "Just starting"
    case .hare: "Getting going"
    case .frog: "Reading well"
    case .crow, .cat, .crab, .grasshopper: "Reading level \(level)"
    }
  }

  public var examples: [String] {
    switch self {
    case .bunny: ["sat", "hop", "red"]
    case .hare: ["frog", "ship", "hill"]
    case .frog: ["lake", "kite", "home"]
    case .crow: ["rain", "boat", "garden"]
    case .cat: ["jumping", "sunflower", "rested"]
    case .crab: ["because", "beautiful", "island"]
    case .grasshopper: ["adventure", "enormous", "whispered"]
    }
  }

  public static func at(level: Int) -> Friend {
    allCases[min(max(level, 1), allCases.count) - 1]
  }

  public var startingStoryID: String {
    StoryLibrary.stories(at: level).first?.id ?? StoryLibrary.all[0].id
  }

  public init(startingStoryID: String) {
    self = Self.starters.first { $0.startingStoryID == startingStoryID } ?? .bunny
  }
}
