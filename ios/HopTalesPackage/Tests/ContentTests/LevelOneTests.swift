import Foundation
import Testing

@testable import Content

struct LevelOneTests {
  private static let levelOne = StoryLibrary.stories(at: 1)
  private static let last = levelOne.last!
  private static let tally = JourneyMoment.tally(
    steps: 41, total: 200, goal: 200, bigWords: 0, next: .hare, storiesLeft: 0
  )

  private static func finished(_ stories: [Story] = levelOne) -> Content.Progress {
    Content.Progress(
      completedSentences: Dictionary(uniqueKeysWithValues: stories.map {
        ($0.id, $0.sentences.count)
      })
    )
  }

  @Test func finishingTheLastLevelOneStoryCelebratesAfterTheTally() {
    var progress = Self.finished()
    let moments = progress.celebrateLevelOne(
      after: Self.last, in: [Self.tally], isPlus: false, locksStories: true
    )
    #expect(moments == [Self.tally, .levelOneFinished])
    #expect(progress.levelOneCelebrated)
  }

  @Test func itTakesTheBigStoryCardsPlace() {
    var progress = Self.finished()
    let moments = progress.celebrateLevelOne(
      after: Self.last, in: [Self.tally, .bigStoryReady(.hare)], isPlus: false, locksStories: true
    )
    #expect(moments == [Self.tally, .levelOneFinished])
  }

  @Test func aNewFriendOnTheSameReadFollowsIt() {
    var progress = Self.finished()
    let moments = progress.celebrateLevelOne(
      after: Self.last,
      in: [Self.tally, .newFriend(.hare, via: .trail)],
      isPlus: false,
      locksStories: true
    )
    #expect(moments == [Self.tally, .levelOneFinished, .newFriend(.hare, via: .trail)])
  }

  @Test func theTreatStaysWithTheTallyAndAFullBasketFollows() {
    var progress = Self.finished()
    let treat = JourneyMoment.treat(
      CollectedTreat(friend: .bunny, isTrail: false, isGolden: false), trail: 0
    )
    let moments = progress.celebrateLevelOne(
      after: Self.last,
      in: [Self.tally, treat, .basketFull(.bunny, number: 1)],
      isPlus: false,
      locksStories: true
    )
    #expect(moments == [Self.tally, treat, .levelOneFinished, .basketFull(.bunny, number: 1)])
  }

  @Test func notWhileALevelOneStoryIsLeft() {
    var progress = Self.finished(Array(Self.levelOne.dropLast()))
    let moments = progress.celebrateLevelOne(
      after: Self.levelOne[0], in: [Self.tally], isPlus: false, locksStories: true
    )
    #expect(moments == [Self.tally])
    #expect(!progress.levelOneCelebrated)
  }

  @Test func aStoryPartlyReadIsNotFinished() {
    var progress = Self.finished()
    progress.completedSentences[Self.last.id] = Self.last.sentences.count - 1
    #expect(!progress.hasFinishedLevelOne)
  }

  @Test func onlyOnce() {
    var progress = Self.finished()
    progress.levelOneCelebrated = true
    let moments = progress.celebrateLevelOne(
      after: Self.last, in: [Self.tally, .bigStoryReady(.hare)], isPlus: false, locksStories: true
    )
    #expect(moments == [Self.tally, .bigStoryReady(.hare)])
  }

  @Test func neverForPlus() {
    var progress = Self.finished()
    let moments = progress.celebrateLevelOne(
      after: Self.last, in: [Self.tally], isPlus: true, locksStories: true
    )
    #expect(moments == [Self.tally])
    #expect(!progress.levelOneCelebrated)
  }

  @Test func neverWhileEveryStoryIsOpen() {
    var progress = Self.finished()
    let moments = progress.celebrateLevelOne(
      after: Self.last, in: [Self.tally], isPlus: false, locksStories: false
    )
    #expect(moments == [Self.tally])
    #expect(!progress.levelOneCelebrated)
  }

  @Test func aReaderWhoHadFinishedSeesItAtTheirNextLevelOneStory() {
    var progress = Self.finished()
    let first = Self.levelOne[0]
    let moments = progress.celebrateLevelOne(
      after: first, in: [Self.tally], isPlus: false, locksStories: true
    )
    #expect(moments == [Self.tally, .levelOneFinished])
  }

  @Test func aStoryAboveLevelOneDoesNotShowIt() {
    var progress = Self.finished()
    let moments = progress.celebrateLevelOne(
      after: StoryLibrary.stories(at: 2)[0], in: [Self.tally], isPlus: false, locksStories: true
    )
    #expect(moments == [Self.tally])
    #expect(!progress.levelOneCelebrated)
  }

  @Test func progressSavedBeforeTheFlagHasNotCelebrated() throws {
    let json = Data(#"{"completedSentences":{},"stars":3,"wordsRead":{}}"#.utf8)
    let progress = try JSONDecoder().decode(Content.Progress.self, from: json)
    #expect(!progress.levelOneCelebrated)
  }
}
