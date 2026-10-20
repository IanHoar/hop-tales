import Foundation

public enum Levels {
  public static let goodReadsToNextFriend: [Int: Double] = [
    1: 3.5, 2: 3.5, 3: 4, 4: 4.5, 5: 5, 6: 5.5
  ]
  public static let stepsToNextFriend: [Int: Int] = Dictionary(
    uniqueKeysWithValues: goodReadsToNextFriend.map { level, reads in
      (level, Int((goodRead(at: level) * reads / 10).rounded()) * 10)
    }
  )
  public static let sentenceWords: [Int: ClosedRange<Int>] = [
    1: 3...5, 2: 5...7, 3: 6...8, 4: 7...9, 5: 8...10, 6: 9...12, 7: 10...14
  ]

  public static let stepsPerWord = 1.0
  public static let stepsPerEasierWord = 0.5
  public static let stepsPerBigWord = 5.0
  public static let storyBonus = 20.0
  public static let storyBonusHelpRate = 0.1

  public static let bigWordRate = (early: 1.0 / 20, late: 1.0 / 8)
  public static let bigWordsBackOffHelpRate = 0.2
  public static let earlyBigStoryShare = 0.9

  public static let bigStoryBar = 0.85
  public static let sustainedStories = 8
  public static let sustainedHelpRate = 0.1

  public static func trailGoal(at level: Int) -> Int {
    Int((goodReadsToNextFriend[level] ?? 0).rounded(.up))
  }
  public static let goldenTreatWorth = 3
  public static let goldenHelpRate = 0.1

  public static func treatsForBasket(_ number: Int) -> Int { 3 + number }

  public static var top: Int { Friend.allCases.count }

  public static func goodRead(at level: Int) -> Double {
    let stories = StoryLibrary.stories(at: level)
    guard !stories.isEmpty else { return 0 }
    let words = stories.reduce(0) { $0 + $1.wordCount }
    return Double(words) / Double(stories.count) * stepsPerWord + storyBonus
  }
}
