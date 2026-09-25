import Foundation

public enum Slot: String, Codable, CaseIterable, Hashable, Sendable {
  case head
  case eyes
  case neck
  case body
  case back
  case claws
  case antennae

  public var name: String {
    switch self {
    case .head: "Hats"
    case .eyes: "Glasses"
    case .neck: "Neck"
    case .body: "Coats"
    case .back: "Bags"
    case .claws: "Claws"
    case .antennae: "Antennae"
    }
  }
}

public struct WardrobePart: Codable, Hashable, Sendable {
  public var x: Double
  public var y: Double
  public var w: Double
  public var rot: Double
  public var pivot: [Double]
}

public struct WardrobeItem: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var name: String
  public var slot: Slot
  public var parts: [WardrobePart]
}

public enum WardrobeLibrary {
  public static let all: [Friend: [WardrobeItem]] = {
    guard let url = Bundle.module.url(forResource: "wardrobe", withExtension: "json") else {
      assertionFailure("wardrobe.json is missing from the Content resource bundle")
      return [:]
    }
    do {
      let decoded = try JSONDecoder().decode(
        [String: [WardrobeItem]].self, from: Data(contentsOf: url)
      )
      return Dictionary(uniqueKeysWithValues: decoded.compactMap { key, items in
        Friend(rawValue: key).map { ($0, items) }
      })
    } catch {
      assertionFailure("wardrobe.json could not be decoded: \(error)")
      return [:]
    }
  }()

  public static let wearable: [Friend: [String]] = [
    .hare: ["straw", "bowtie", "crown", "specs", "satchel"],
    .bunny: ["bluebell-crown", "bonnet", "heart-glasses", "daisy-chain", "basket-pack"],
    .frog: ["lilypad-hat", "goggles", "check-bowtie", "reed-satchel", "raincoat"],
    .crow: ["flat-cap", "top-hat", "aviator-goggles", "autumn-scarf", "post-satchel"],
    .cat: ["garden-hat", "beret", "cateye-glasses", "red-bell-collar", "cardigan"],
    .crab: ["sailor-cap", "captain-hat", "diving-mask", "claw-mittens", "chest-pack"],
    .grasshopper: [
      "acorn-cap", "antenna-poms", "explorer-goggles", "clover-bowtie", "ladybird-cape"
    ]
  ]

  @TaskLocal public static var painted: [Friend: Set<String>] = {
    guard
      let url = Bundle.module.url(forResource: "looks", withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let decoded = try? JSONDecoder().decode([String: [String]].self, from: data)
    else {
      assertionFailure("looks.json is missing or unreadable; run scripts/export-looks.py")
      return [:]
    }
    return Dictionary(uniqueKeysWithValues: decoded.compactMap { key, ids in
      Friend(rawValue: key).map { ($0, Set(ids)) }
    })
  }()

  public static func items(for friend: Friend) -> [WardrobeItem] {
    let library = all[friend] ?? []
    let painted = painted[friend] ?? []
    return (wearable[friend] ?? []).filter(painted.contains).compactMap { id in
      library.first { $0.id == id }
    }
  }

  public static func slots(for friend: Friend) -> [Slot] {
    let used = Set(items(for: friend).map(\.slot))
    return Slot.allCases.filter(used.contains)
  }
}

extension Progress {
  public func unlockedCount(for friend: Friend) -> Int {
    guard journey.met.contains(friend) else { return 0 }
    let items = WardrobeLibrary.items(for: friend).count
    return min(1 + (baskets[friend]?.filled ?? 0), items)
  }

  public func isUnlocked(_ item: WardrobeItem, for friend: Friend) -> Bool {
    guard let index = WardrobeLibrary.items(for: friend).firstIndex(of: item) else { return false }
    return index < unlockedCount(for: friend)
  }

  public func newestItem(for friend: Friend) -> WardrobeItem? {
    let count = unlockedCount(for: friend)
    return count > 0 ? WardrobeLibrary.items(for: friend)[count - 1] : nil
  }

  public func outfit(for friend: Friend) -> [WardrobeItem] {
    let chosen = outfits[friend] ?? [:]
    return WardrobeLibrary.items(for: friend).filter { item in
      chosen[item.slot] == item.id && isUnlocked(item, for: friend)
    }
  }

  public mutating func wear(_ item: WardrobeItem, on friend: Friend) {
    guard isUnlocked(item, for: friend) else { return }
    outfits[friend] = [item.slot: item.id]
  }

  public mutating func takeOff(_ slot: Slot, from friend: Friend) {
    outfits[friend]?[slot] = nil
  }
}

extension JourneyMoment {
  public var unlockedItem: WardrobeItem? {
    guard case let .basketFull(friend, number) = self else { return nil }
    let items = WardrobeLibrary.items(for: friend)
    return number < items.count ? items[number] : nil
  }
}
