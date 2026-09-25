import Foundation
import Testing

@testable import Content

struct JourneyTests {
  static func words(_ story: String) -> Int { StoryLibrary[story]?.wordCount ?? 0 }

  @Test func startingWithAFriendMeetsTheEasierOnes() {
    let journey = Journey(starting: .frog)
    #expect(journey.level == 3)
    #expect(journey.met == [.bunny, .hare, .frog])
    #expect(journey.activeFriend == .frog)
    #expect(journey.nextFriend == .crow)
  }

  @Test func wordsAtYourLevelAreAStepAndBigWordsAreFive() throws {
    let journey = Journey(starting: .bunny)
    let story = try #require(StoryLibrary["bramble-bug"])
    let result = StoryResult(storyID: story.id, wordsRead: 20, bigWordsRead: 2, helpedWords: 5)
    #expect(journey.stepsEarned(by: result, in: story) == 18 + 10)
  }

  @Test func aStoryReadWithLittleHelpEarnsTheBonus() throws {
    let journey = Journey(starting: .bunny)
    let story = try #require(StoryLibrary["bramble-bug"])
    let result = StoryResult(storyID: story.id, wordsRead: 20)
    #expect(journey.stepsEarned(by: result, in: story) == 20 + Levels.storyBonus)
  }

  @Test func easierStoriesEarnHalfAStepAndNoBonus() throws {
    let journey = Journey(starting: .hare)
    let story = try #require(StoryLibrary["bramble-bug"])
    let result = StoryResult(storyID: story.id, wordsRead: 20)
    #expect(journey.stepsEarned(by: result, in: story) == 10)
  }

  @Test func helpNeverCostsAStep() throws {
    let journey = Journey(starting: .bunny)
    let story = try #require(StoryLibrary["bramble-bug"])
    let alone = StoryResult(storyID: story.id, wordsRead: 20, helpedWords: 3)
    let helped = StoryResult(storyID: story.id, wordsRead: 20, helpedWords: 20)
    #expect(journey.stepsEarned(by: alone, in: story) == journey.stepsEarned(by: helped, in: story))
  }

  @Test func aFullPathOffersTheBigStory() {
    var journey = Journey(starting: .bunny)
    journey.steps = journey.goal - 5
    let moments = journey.record(StoryResult(storyID: "bramble-bug", wordsRead: 10, helpedWords: 5))
    #expect(journey.isPathFull)
    #expect(moments.last == .bigStoryReady(.hare))
    #expect(journey.bigStory?.id == "hare-big-story")
    #expect(journey.steps == journey.goal)
  }

  @Test func readingTheBigStoryWellMeetsTheNextFriend() {
    var journey = Journey(starting: .bunny)
    journey.steps = journey.goal
    let words = Self.words("hare-big-story")
    let moments = journey.record(
      StoryResult(storyID: "hare-big-story", wordsRead: words, helpedWords: 2)
    )
    #expect(moments == [.newFriend(.hare, via: .bigStory)])
    #expect(journey.level == 2)
    #expect(journey.activeFriend == .hare)
    #expect(journey.met.contains(.hare))
    #expect(journey.steps == 0)
  }

  @Test func aBigStoryWithTooMuchHelpIsNotYetAndNothingIsLost() {
    var journey = Journey(starting: .bunny)
    journey.steps = journey.goal
    let words = Self.words("hare-big-story")
    let moments = journey.record(
      StoryResult(storyID: "hare-big-story", wordsRead: words, helpedWords: words / 2)
    )
    #expect(moments == [.notYet(.hare)])
    #expect(journey.level == 1)
    #expect(journey.isPathFull)
    #expect(journey.bigStoryAttempts == 1)
  }

  @Test func eightStoriesReadWellMoveUpWithoutTheBigStory() {
    var journey = Journey(starting: .bunny)
    var last: [JourneyMoment] = []
    for _ in 0..<Levels.sustainedStories {
      last = journey.record(StoryResult(storyID: "big-nap", wordsRead: 1))
    }
    #expect(last.last == .newFriend(.hare, via: .sustainedReading))
    #expect(journey.level == 2)
    #expect(journey.storiesReadWell == 0)
  }

  @Test func sixTrailTreatsBringTheNextFriend() {
    var journey = Journey(starting: .hare)
    let trail = CollectedTreat(friend: .frog, isTrail: true, isGolden: false)
    var last: [JourneyMoment] = []
    for _ in 0..<Levels.trailGoal {
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
    let moments = journey.record(StoryResult(storyID: "sprig-fiddle", wordsRead: 40))
    #expect(moments.isEmpty)
    #expect(!journey.isPathFull)
  }

  @Test func bigWordsRiseAsThePathFillsAndBackOffWhenItIsHard() throws {
    let story = try #require(StoryLibrary["sprig-journey"])
    var journey = Journey(starting: .bunny)
    journey.level = 7
    let early = journey.bigWords(in: story)
    journey.steps = 1_000
    journey.level = 6
    let late = journey.bigWords(in: StoryLibrary["nipper-storm"]!)
    #expect(early.count <= late.count + 2)
    journey.recentHelpRates = [0.5, 0.5, 0.5]
    #expect(journey.bigWordShare == Levels.bigWordRate.early)
  }

  @Test func easierAndBigStoriesShowNoBigWords() throws {
    let journey = Journey(starting: .frog)
    #expect(journey.bigWords(in: try #require(StoryLibrary["bramble-bug"])).isEmpty)
    #expect(journey.bigWords(in: try #require(StoryLibrary["puddle-big-story"])).isEmpty)
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

  @Test func aProgressFileFromBeforeTheJourneyStartsFresh() throws {
    let json = #"{"completedSentences":{},"stars":4,"wordsRead":{}}"#
    let progress = try JSONDecoder().decode(Progress.self, from: Data(json.utf8))
    #expect(progress.journey == Journey())
    #expect(progress.stars == 4)
  }
}
