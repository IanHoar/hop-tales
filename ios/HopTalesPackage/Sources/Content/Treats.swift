import Foundation

public struct StoryTreat: Codable, Hashable, Sendable {
  public var word: WordRef
  public var friend: Friend
  public var isTrail: Bool

  public init(word: WordRef, friend: Friend, isTrail: Bool) {
    self.word = word
    self.friend = friend
    self.isTrail = isTrail
  }
}

public struct CollectedTreat: Hashable, Sendable {
  public var friend: Friend
  public var isTrail: Bool
  public var isGolden: Bool

  public init(friend: Friend, isTrail: Bool, isGolden: Bool) {
    self.friend = friend
    self.isTrail = isTrail
    self.isGolden = isGolden
  }

  public var worth: Int { isGolden ? Levels.goldenTreatWorth : 1 }
}

public struct Basket: Codable, Hashable, Sendable {
  public var total = 0
  public var golden = 0
  public var filled = 0
  public var inBasket = 0

  public init() {}

  public var goal: Int { Levels.treatsForBasket(filled + 1) }

  public mutating func add(_ treat: CollectedTreat) -> Int {
    total += treat.worth
    if treat.isGolden { golden += 1 }
    inBasket += treat.worth
    var presents = 0
    while inBasket >= goal {
      inBasket -= goal
      filled += 1
      presents += 1
    }
    return presents
  }
}

extension Journey {
  public func treat(in story: Story) -> StoryTreat? {
    guard !story.isBigStory, let last = story.sentences.indices.last else { return nil }
    let words = story.sentences[last].words.count
    guard words > 1 else { return nil }
    let word = WordRef(sentence: last, word: (words - 1) / 2)
    if story.stretch, story.level == level, let next = nextFriend {
      return StoryTreat(word: word, friend: next, isTrail: true)
    }
    return StoryTreat(word: word, friend: story.friend, isTrail: false)
  }
}

extension Progress {
  public mutating func collect(_ treat: CollectedTreat) -> [JourneyMoment] {
    guard !treat.isTrail else { return [] }
    var basket = baskets[treat.friend] ?? Basket()
    let presents = basket.add(treat)
    baskets[treat.friend] = basket
    return (0..<presents).map { offset in
      .basketFull(treat.friend, number: basket.filled - presents + offset + 1)
    }
  }
}
