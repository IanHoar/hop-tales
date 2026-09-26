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
    case .bunny: "Bob"
    case .hare: "Skip"
    case .frog: "Oggy"
    case .crow: "Button"
    case .cat: "Marmalade"
    case .crab: "Barnacle"
    case .grasshopper: "Bartholomew"
    }
  }

  public var level: Int { (Self.allCases.firstIndex(of: self) ?? 0) + 1 }

  public var stage: String {
    Phonics.shared.phase(at: level) ?? "Reading level \(level)"
  }

  public var examples: [String] {
    switch self {
    case .bunny: ["sat", "hop", "red"]
    case .hare: ["ship", "duck", "frog"]
    case .frog: ["lake", "kite", "home"]
    case .crow: ["jumped", "farm", "garden"]
    case .cat: ["rain", "boat", "moon"]
    case .crab: ["knock", "tiny", "bottle"]
    case .grasshopper: ["station", "adventure", "enormous"]
    }
  }

  public var world: String {
    switch self {
    case .bunny: "Bluebell Wood"
    case .hare: "The Meadow"
    case .frog: "Willow Pond"
    case .crow: "Harvest Field"
    case .cat: "Cottage Garden"
    case .crab: "Rock Pools"
    case .grasshopper: "Tall Grass"
    }
  }

  public var place: String {
    switch self {
    case .bunny: "the wood"
    case .hare: "the meadow"
    case .frog: "the pond"
    case .crow: "the field"
    case .cat: "the garden"
    case .crab: "the rock pools"
    case .grasshopper: "the tall grass"
    }
  }

  public var treat: Treat {
    switch self {
    case .bunny: Treat(one: "strawberry", many: "strawberries", art: "strawberry")
    case .hare: Treat(one: "carrot", many: "carrots", art: "carrot")
    case .frog: Treat(one: "water lily", many: "water lilies", art: "lily")
    case .crow: Treat(one: "button", many: "buttons", art: "button")
    case .cat: Treat(one: "ball of wool", many: "balls of wool", art: "yarn")
    case .crab: Treat(one: "shell", many: "shells", art: "shell")
    case .grasshopper: Treat(one: "clover leaf", many: "clover leaves", art: "clover")
    }
  }

  public var gift: String {
    switch self {
    case .bunny: "a bluebell crown"
    case .hare: "a straw hat"
    case .frog: "a lily-pad hat"
    case .crow: "a tweed flat cap"
    case .cat: "a gardening hat"
    case .crab: "a sailor cap"
    case .grasshopper: "an acorn cap"
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

public struct Treat: Hashable, Sendable {
  public var one: String
  public var many: String
  public var art: String
}
