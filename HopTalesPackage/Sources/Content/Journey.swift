import Foundation

public struct WordRef: Codable, Hashable, Sendable {
  public var sentence: Int
  public var word: Int

  public init(sentence: Int, word: Int) {
    self.sentence = sentence
    self.word = word
  }
}

public struct StoryResult: Equatable, Sendable {
  public var storyID: String
  public var wordsRead: Int
  public var bigWordsRead: Int
  public var helpedWords: Int
  public var trailCollected: Int

  public init(
    storyID: String,
    wordsRead: Int,
    bigWordsRead: Int = 0,
    helpedWords: Int = 0,
    trailCollected: Int = 0
  ) {
    self.storyID = storyID
    self.wordsRead = wordsRead
    self.bigWordsRead = bigWordsRead
    self.helpedWords = helpedWords
    self.trailCollected = trailCollected
  }

  public var helpRate: Double {
    wordsRead > 0 ? Double(helpedWords) / Double(wordsRead) : 0
  }
}

public enum LevelUp: String, Codable, Hashable, Sendable {
  case bigStory
  case sustainedReading
  case trail
}

public enum JourneyMoment: Equatable, Sendable {
  case tally(steps: Double, total: Double, goal: Double, bigWords: Int, next: Friend)
  case bigStoryReady(Friend)
  case notYet(Friend)
  case newFriend(Friend, via: LevelUp)
}

extension JourneyMoment {
  public var isCallout: Bool {
    if case .tally = self { return false }
    return true
  }

  public var story: Story? {
    switch self {
    case let .bigStoryReady(friend): StoryLibrary.bigStory(at: friend.level)
    case let .newFriend(friend, _): StoryLibrary.stories(at: friend.level).first
    case .tally, .notYet: nil
    }
  }
}

public struct Journey: Codable, Hashable, Sendable {
  public var level: Int
  public var steps: Double
  public var met: Set<Friend>
  public var activeFriend: Friend
  public var bigStoryAttempts: Int
  public var trail: Int
  public var storiesReadWell: Int
  public var recentHelpRates: [Double]
  public var cleanStreak: Int

  public init(starting friend: Friend = .bunny) {
    level = friend.level
    steps = 0
    met = Set(Friend.allCases.filter { $0.level <= friend.level })
    activeFriend = friend
    bigStoryAttempts = 0
    trail = 0
    storiesReadWell = 0
    recentHelpRates = []
    cleanStreak = 0
  }

  public var nextFriend: Friend? {
    level < Levels.top ? Friend.at(level: level + 1) : nil
  }

  public var goal: Double {
    Double(Levels.stepsToNextFriend[level] ?? 0)
  }

  public var fill: Double {
    goal > 0 ? min(steps / goal, 1) : 1
  }

  public var isPathFull: Bool {
    guard nextFriend != nil else { return false }
    let share = cleanStreak >= 3 ? Levels.earlyBigStoryShare : 1
    return steps >= goal * share
  }

  public var bigStory: Story? {
    guard isPathFull else { return nil }
    return StoryLibrary.bigStory(at: level + 1)
  }

  public var bigWordShare: Double {
    let rates = Levels.bigWordRate
    let struggling = recentHelpRates.count == 3
      && recentHelpRates.reduce(0, +) / 3 > Levels.bigWordsBackOffHelpRate
    if struggling { return rates.early }
    let boost = bigStoryAttempts > 0 ? 1 : fill
    return rates.early + (rates.late - rates.early) * boost
  }

  public func bigWords(in story: Story) -> Set<WordRef> {
    guard !story.isBigStory, story.level >= level else { return [] }
    let marked = story.sentences.enumerated().flatMap { sentence, words in
      words.words.enumerated().compactMap { index, word in
        word.big ? WordRef(sentence: sentence, word: index) : nil
      }
    }
    let wanted = Int((Double(story.wordCount) * bigWordShare).rounded())
    guard wanted < marked.count else { return Set(marked) }
    guard wanted > 0 else { return [] }
    let stride = Double(marked.count) / Double(wanted)
    return Set((0..<wanted).map { marked[Int(Double($0) * stride)] })
  }

  public func stepsEarned(by result: StoryResult, in story: Story) -> Double {
    guard !story.isBigStory, nextFriend != nil else { return 0 }
    let atLevel = story.level >= level
    let perWord = atLevel ? Levels.stepsPerWord : Levels.stepsPerEasierWord
    let plain = Double(result.wordsRead - result.bigWordsRead) * perWord
    let big = Double(result.bigWordsRead) * Levels.stepsPerBigWord
    let bonus = atLevel && result.helpRate <= Levels.storyBonusHelpRate ? Levels.storyBonus : 0
    return plain + big + bonus
  }

  public mutating func record(_ result: StoryResult) -> [JourneyMoment] {
    guard let story = StoryLibrary[result.storyID] else { return [] }
    if story.isBigStory {
      return recordBigStory(result, story: story)
    }
    recentHelpRates = Array((recentHelpRates + [result.helpRate]).suffix(3))
    cleanStreak = result.helpedWords == 0 ? cleanStreak + 1 : 0
    guard let next = nextFriend else { return [] }

    let earned = stepsEarned(by: result, in: story)
    steps = min(steps + earned, goal)
    var moments: [JourneyMoment] = [
      .tally(steps: earned, total: steps, goal: goal, bigWords: result.bigWordsRead, next: next)
    ]

    let readWell = result.helpRate <= Levels.sustainedHelpRate
    if story.level >= level, readWell { storiesReadWell += 1 }
    trail += result.trailCollected

    if trail >= Levels.trailGoal, let friend = levelUp() {
      moments.append(.newFriend(friend, via: .trail))
    } else if storiesReadWell >= Levels.sustainedStories, let friend = levelUp() {
      moments.append(.newFriend(friend, via: .sustainedReading))
    } else if isPathFull, let friend = nextFriend {
      moments.append(.bigStoryReady(friend))
    }
    return moments
  }

  private mutating func recordBigStory(_ result: StoryResult, story: Story) -> [JourneyMoment] {
    guard story.level == level + 1, let friend = nextFriend else { return [] }
    guard result.helpRate <= 1 - Levels.bigStoryBar else {
      bigStoryAttempts += 1
      return [.notYet(friend)]
    }
    _ = levelUp()
    return [.newFriend(friend, via: .bigStory)]
  }

  @discardableResult
  private mutating func levelUp() -> Friend? {
    guard let friend = nextFriend else { return nil }
    level += 1
    met.insert(friend)
    activeFriend = friend
    steps = 0
    trail = 0
    storiesReadWell = 0
    bigStoryAttempts = 0
    return friend
  }

  public mutating func readWith(_ friend: Friend) {
    guard met.contains(friend) else { return }
    activeFriend = friend
  }

  public mutating func grownUpMoves(to friend: Friend) {
    guard met.contains(friend) || Friend.starters.contains(friend) else { return }
    if friend.level > level {
      self = Journey(starting: friend)
      return
    }
    activeFriend = friend
  }
}
