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
    .hare: ["scarf", "straw", "bowtie", "crown", "specs", "satchel"],
    .bunny: ["bow", "bluebell-crown", "bonnet", "heart-glasses", "daisy-chain", "basket-pack"],
    .frog: ["neckerchief", "lilypad-hat", "goggles", "check-bowtie", "reed-satchel", "raincoat"],
    .crow: ["knit-cap", "flat-cap", "top-hat", "aviator-goggles", "autumn-scarf", "post-satchel"],
    .cat: ["sage-collar", "garden-hat", "beret", "cateye-glasses", "red-bell-collar", "cardigan"],
    .crab: [
      "sailor-kerchief", "sailor-cap", "captain-hat", "diving-mask", "life-ring", "claw-mittens"
    ],
    .grasshopper: [
      "acorn-cap", "antenna-poms", "explorer-goggles", "clover-bowtie", "ladybird-cape"
    ]
  ]

  public static let starting: [Friend: String] = [
    .bunny: "bow", .hare: "scarf", .frog: "neckerchief", .crow: "knit-cap",
    .cat: "sage-collar", .crab: "sailor-kerchief"
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

  public static func startingItem(for friend: Friend) -> WardrobeItem? {
    starting[friend].flatMap { id in items(for: friend).first { $0.id == id } }
  }

  public static func unlockable(for friend: Friend) -> [WardrobeItem] {
    items(for: friend).filter { $0.id != starting[friend] }
  }
}

extension Progress {
  public func unlockedCount(for friend: Friend) -> Int {
    guard journey.met.contains(friend) else { return 0 }
    let items = WardrobeLibrary.unlockable(for: friend).count
    return min(1 + (baskets[friend]?.filled ?? 0), items)
  }

  public func isUnlocked(_ item: WardrobeItem, for friend: Friend) -> Bool {
    if item == WardrobeLibrary.startingItem(for: friend) { return true }
    guard let index = WardrobeLibrary.unlockable(for: friend).firstIndex(of: item) else {
      return false
    }
    return index < unlockedCount(for: friend)
  }

  public func newestItem(for friend: Friend) -> WardrobeItem? {
    let count = unlockedCount(for: friend)
    return count > 0 ? WardrobeLibrary.unlockable(for: friend)[count - 1] : nil
  }

  public func outfit(for friend: Friend) -> [WardrobeItem] {
    let chosen = choices(for: friend)
    return WardrobeLibrary.items(for: friend).filter { item in
      chosen[item.slot] == item.id && isUnlocked(item, for: friend)
    }
  }

  public mutating func wear(_ item: WardrobeItem, on friend: Friend) {
    guard isUnlocked(item, for: friend) else { return }
    outfits[friend] = [item.slot: item.id]
  }

  public mutating func undress(_ friend: Friend) {
    outfits[friend] = [:]
  }

  public mutating func takeOff(_ slot: Slot, from friend: Friend) {
    var chosen = choices(for: friend)
    chosen[slot] = nil
    outfits[friend] = chosen
  }

  private func choices(for friend: Friend) -> [Slot: String] {
    if let chosen = outfits[friend] { return chosen }
    guard let item = WardrobeLibrary.startingItem(for: friend) else { return [:] }
    return [item.slot: item.id]
  }
}

extension JourneyMoment {
  public var unlockedItem: WardrobeItem? {
    guard case let .basketFull(friend, number) = self else { return nil }
    let items = WardrobeLibrary.unlockable(for: friend)
    return number < items.count ? items[number] : nil
  }
}
