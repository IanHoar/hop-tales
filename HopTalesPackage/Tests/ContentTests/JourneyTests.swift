import Foundation
import Testing

@testable import Content

struct JourneyTests {
  static func words(_ story: String) -> Int { StoryLibrary[story]?.wordCount ?? 0 }

  static func everyStoryRead(_ journey: inout Journey) {
    journey.storiesRead = Set(StoryLibrary.stories(at: journey.level).map(\.id))
  }

  @Test func startingWithAFriendMeetsTheEasierOnes() {
    let journey = Journey(starting: .frog)
    #expect(journey.level == 3)
    #expect(journey.met == [.bunny, .hare, .frog])
    #expect(journey.activeFriend == .frog)
    #expect(journey.nextFriend == .crow)
  }

  @Test func wordsAtYourLevelAreAStepAndBigWordsAreFive() throws {
    let journey = Journey(starting: .bunny)
    let story = try #require(StoryLibrary["bob-bug"])
    let result = StoryResult(storyID: story.id, wordsRead: 20, bigWordsRead: 2, helpedWords: 5)
    #expect(journey.stepsEarned(by: result, in: story) == 18 + 10)
  }

  @Test func aStoryReadWithLittleHelpEarnsTheBonus() throws {
    let journey = Journey(starting: .bunny)
    let story = try #require(StoryLibrary["bob-bug"])
    let result = StoryResult(storyID: story.id, wordsRead: 20)
    #expect(journey.stepsEarned(by: result, in: story) == 20 + Levels.storyBonus)
  }

  @Test func easierStoriesEarnHalfAStepAndNoBonus() throws {
    let journey = Journey(starting: .hare)
    let story = try #require(StoryLibrary["bob-bug"])
    let result = StoryResult(storyID: story.id, wordsRead: 20)
    #expect(journey.stepsEarned(by: result, in: story) == 10)
  }

  @Test func helpNeverCostsAStep() throws {
    let journey = Journey(starting: .bunny)
    let story = try #require(StoryLibrary["bob-bug"])
    let alone = StoryResult(storyID: story.id, wordsRead: 20, helpedWords: 3)
    let helped = StoryResult(storyID: story.id, wordsRead: 20, helpedWords: 20)
    #expect(journey.stepsEarned(by: alone, in: story) == journey.stepsEarned(by: helped, in: story))
  }

  @Test func aFullPathOffersTheBigStory() {
    var journey = Journey(starting: .bunny)
    Self.everyStoryRead(&journey)
    journey.steps = journey.goal - 5
    let moments = journey.record(StoryResult(storyID: "bob-bug", wordsRead: 10, helpedWords: 5))
    #expect(journey.isPathFull)
    #expect(moments.last == .bigStoryReady(.hare))
    #expect(journey.bigStory?.id == "skip-big-story")
    #expect(journey.steps == journey.goal)
  }

  @Test func readingTheBigStoryWellMeetsTheNextFriend() {
    var journey = Journey(starting: .bunny)
    Self.everyStoryRead(&journey)
    journey.steps = journey.goal
    let words = Self.words("skip-big-story")
    let moments = journey.record(
      StoryResult(storyID: "skip-big-story", wordsRead: words, helpedWords: 2)
    )
    #expect(moments == [.newFriend(.hare, via: .bigStory)])
    #expect(journey.level == 2)
    #expect(journey.activeFriend == .hare)
    #expect(journey.met.contains(.hare))
    #expect(journey.steps == 0)
  }

  @Test func aBigStoryWithTooMuchHelpIsNotYetAndNothingIsLost() {
    var journey = Journey(starting: .bunny)
    Self.everyStoryRead(&journey)
    journey.steps = journey.goal
    let words = Self.words("skip-big-story")
    let moments = journey.record(
      StoryResult(storyID: "skip-big-story", wordsRead: words, helpedWords: words / 2)
    )
    #expect(moments == [.notYet(.hare)])
    #expect(journey.level == 1)
    #expect(journey.isPathFull)
    #expect(journey.bigStoryAttempts == 1)
  }

  @Test func theNextFriendIsAFewGoodReadsAwayAndTheRoutesStayBalanced() {
    #expect(Levels.stepsToNextFriend == [1: 170, 2: 200, 3: 250, 4: 320, 5: 390, 6: 460])
    for level in 1..<Levels.top {
      let reads = Double(Levels.stepsToNextFriend[level] ?? 0) / Levels.goodRead(at: level)
      #expect((3...6).contains(reads), "level \(level)")
      #expect(Levels.trailGoal(at: level) >= Int(reads.rounded(.down)), "level \(level)")
      #expect(Levels.trailGoal(at: level) < Levels.sustainedStories, "level \(level)")
    }
  }

  @Test func theNextFriendWaitsUntilEveryStoryAtTheLevelIsRead() {
    var journey = Journey(starting: .bunny)
    journey.steps = journey.goal
    journey.trail = Levels.trailGoal(at: 1)
    journey.storiesReadWell = Levels.sustainedStories
    let stories = StoryLibrary.stories(at: 1)
    #expect(!journey.isPathFull)
    for story in stories.dropLast() {
      let moments = journey.record(StoryResult(storyID: story.id, wordsRead: 5))
      #expect(journey.level == 1)
      #expect(moments.allSatisfy { !$0.isCallout })
    }
    #expect(journey.storiesLeft.map(\.id) == [stories.last?.id])
    let moments = journey.record(StoryResult(storyID: stories[stories.count - 1].id, wordsRead: 5))
    #expect(moments.last == .newFriend(.hare, via: .trail))
    #expect(journey.storiesRead.isEmpty)
  }

  @Test func easierStoriesDoNotCountTowardsTheLevel() {
    var journey = Journey(starting: .hare)
    _ = journey.record(StoryResult(storyID: "bob-bug", wordsRead: 5))
    #expect(journey.storiesRead.isEmpty)
    #expect(journey.storiesLeft.count == StoryLibrary.stories(at: 2).count)
  }

  @Test func eightStoriesReadWellMoveUpWithoutTheBigStory() {
    var journey = Journey(starting: .bunny)
    Self.everyStoryRead(&journey)
    var last: [JourneyMoment] = []
    for _ in 0..<Levels.sustainedStories {
      last = journey.record(StoryResult(storyID: "big-nap", wordsRead: 1))
    }
    #expect(last.last == .newFriend(.hare, via: .sustainedReading))
    #expect(journey.level == 2)
    #expect(journey.storiesReadWell == 0)
  }

  @Test func aFullTrailBringsTheNextFriend() {
    var journey = Journey(starting: .hare)
    Self.everyStoryRead(&journey)
    let trail = CollectedTreat(friend: .frog, isTrail: true, isGolden: false)
    var last: [JourneyMoment] = []
    for _ in 0..<Levels.trailGoal(at: 2) {
      last = journey.record(
        StoryResult(storyID: "crunchy-carrot", wordsRead: 5, helpedWords: 5, treat: trail)
      )
    }
    #expect(last.last == .newFriend(.frog, via: .trail))
    #expect(journey.trail == 0)
  }

  @Test func theTopFriendHasNoPathToFill() {
    var journey = Journey(starting: .bunny)
    journey.level = 7
    journey.activeFriend = .grasshopper
    let moments = journey.record(StoryResult(storyID: "bartholomew-fiddle", wordsRead: 40))
    #expect(moments.isEmpty)
    #expect(!journey.isPathFull)
  }

  @Test func bigWordsRiseAsThePathFillsAndBackOffWhenItIsHard() throws {
    let story = try #require(StoryLibrary["bartholomew-journey"])
    var journey = Journey(starting: .bunny)
    journey.level = 7
    let early = journey.bigWords(in: story)
    journey.steps = 1_000
    journey.level = 6
    let late = journey.bigWords(in: StoryLibrary["barnacle-storm"]!)
    #expect(early.count <= late.count + 2)
    journey.recentHelpRates = [0.5, 0.5, 0.5]
    #expect(journey.bigWordShare == Levels.bigWordRate.early)
  }

  @Test func easierAndBigStoriesShowNoBigWords() throws {
    let journey = Journey(starting: .frog)
    #expect(journey.bigWords(in: try #require(StoryLibrary["bob-bug"])).isEmpty)
    #expect(journey.bigWords(in: try #require(StoryLibrary["oggy-big-story"])).isEmpty)
  }

  @Test func aGrownUpCanMoveBetweenMetFriendsButNotSkipPastLevelThree() {
    var journey = Journey(starting: .bunny)
    journey.grownUpMoves(to: .frog)
    #expect(journey.level == 3)
    journey.grownUpMoves(to: .crow)
    #expect(journey.activeFriend == .frog)
    journey.grownUpMoves(to: .bunny)
    #expect(journey.activeFriend == .bunny)
    #expect(journey.level == 3)
  }

  @Test func aSavedJourneyCountsTheStoriesAlreadyFinished() throws {
    let journey = """
      {"level":1,"steps":40,"met":["bunny"],"activeFriend":"bunny","bigStoryAttempts":0,
      "trail":0,"storiesReadWell":0,"recentHelpRates":[],"cleanStreak":0}
      """
    let json = """
      {"completedSentences":{"bob-bug":6,"meadow-walk":2},"stars":4,"wordsRead":{},
      "journey":\(journey)}
      """
    let progress = try JSONDecoder().decode(Progress.self, from: Data(json.utf8))
    #expect(progress.journey.steps == 40)
    #expect(progress.journey.storiesRead == ["bob-bug"])
  }

  @Test func aProgressFileFromBeforeTheJourneyStartsFresh() throws {
    let json = #"{"completedSentences":{},"stars":4,"wordsRead":{}}"#
    let progress = try JSONDecoder().decode(Progress.self, from: Data(json.utf8))
    #expect(progress.journey == Journey())
    #expect(progress.stars == 4)
  }
}
