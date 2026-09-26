import Foundation

public struct StoryEvent: Codable, Hashable, Sendable {
  public enum Place: String, Codable, Hashable, Sendable {
    case ground
    case near
    case sky
  }

  public var prop: String
  public var count: Int
  public var after: Int?
  public var place: Place?

  public init(prop: String, count: Int = 1, after: Int? = nil, place: Place? = nil) {
    self.prop = prop
    self.count = count
    self.after = after
    self.place = place
  }

  public var resolvedPlace: Place {
    place ?? StoryProp.named(prop)?.place ?? .ground
  }
}

public struct StoryProp: Codable, Hashable, Sendable {
  public enum Motion: String, Codable, Hashable, Sendable {
    case walk
    case swim
    case fly
    case perch
    case swoop
    case pop
    case burst
    case drift
    case sway
    case roll
    case bob
    case fade

    public var frames: Int {
      switch self {
      case .walk, .swim, .fly, .perch, .swoop: 2
      default: 1
      }
    }
  }

  public var motion: Motion
  public var place: StoryEvent.Place
  public var height: Double
  public var sticker: Bool?

  public var isSticker: Bool { sticker ?? true }

  public static let all: [String: StoryProp] = {
    guard
      let url = Bundle.module.url(forResource: "props", withExtension: "json"),
      let props = try? JSONDecoder().decode([String: StoryProp].self, from: Data(contentsOf: url))
    else {
      assertionFailure("props.json could not be decoded")
      return [:]
    }
    return props
  }()

  public static func named(_ name: String) -> StoryProp? { all[name] }

  public static let largest = 260.0

  public func height(in world: Friend) -> Double {
    isSticker ? min(height * world.propScale, Self.largest) : height
  }
}

extension Friend {
  public var propScale: Double {
    switch self {
    case .bunny: 1.2
    case .hare, .crow, .cat: 1
    case .frog: 2
    case .crab: 2.2
    case .grasshopper: 4
    }
  }
}
