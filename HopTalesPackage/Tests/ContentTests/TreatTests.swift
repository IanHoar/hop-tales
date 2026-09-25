import Testing

@testable import Content

struct TreatTests {
  @Test func aStoryHasOneTreatInItsLastSentence() throws {
    let story = try #require(StoryLibrary["bramble-bug"])
    let treat = try #require(Journey(starting: .bunny).treat(in: story))
    #expect(treat.word.sentence == story.sentences.count - 1)
    #expect(treat.friend == .bunny)
    #expect(!treat.isTrail)
  }

  @Test func stretchStoriesAtYourLevelCarryTheNextFriendsTreat() throws {
    let journey = Journey(starting: .bunny)
    let stretch = try #require(journey.treat(in: StoryLibrary["big-nap"]!))
    #expect(stretch.isTrail)
    #expect(stretch.friend == .hare)
    let easier = try #require(Journey(starting: .hare).treat(in: StoryLibrary["big-nap"]!))
    #expect(!easier.isTrail)
  }

  @Test func bigStoriesHaveNoTreat() {
    #expect(Journey(starting: .bunny).treat(in: StoryLibrary["hare-big-story"]!) == nil)
  }

  @Test func basketsNeedThreePlusTheirNumber() {
    var progress = Progress()
    let plain = CollectedTreat(friend: .bunny, isTrail: false, isGolden: false)
    var moments: [JourneyMoment] = []
    for _ in 0..<4 { moments += progress.collect(plain) }
    #expect(moments == [.basketFull(.bunny, number: 1)])
    #expect(progress.baskets[.bunny]?.goal == 5)
  }

  @Test func aGoldenTreatCountsThree() {
    var progress = Progress()
    let golden = CollectedTreat(friend: .hare, isTrail: false, isGolden: true)
    _ = progress.collect(golden)
    #expect(progress.baskets[.hare]?.inBasket == 3)
    #expect(progress.baskets[.hare]?.golden == 1)
  }

  @Test func trailTreatsNeverGoInABasket() {
    var progress = Progress()
    let trail = CollectedTreat(friend: .frog, isTrail: true, isGolden: false)
    #expect(progress.collect(trail).isEmpty)
    #expect(progress.baskets.isEmpty)
  }
}
