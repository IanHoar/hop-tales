import Foundation

public enum Levels {
  public static let stepsToNextFriend: [Int: Int] = [1: 300, 2: 400, 3: 500, 4: 600, 5: 700, 6: 800]
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

  public static let trailGoal = 6
  public static let goldenTreatWorth = 3
  public static let goldenHelpRate = 0.1

  public static func treatsForBasket(_ number: Int) -> Int { 3 + number }

  public static var top: Int { Friend.allCases.count }
}
