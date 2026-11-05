import CoreGraphics
import Testing

@testable import Reading

struct FinishCheerTests {
  let word = CGPoint(x: 200, y: 600)
  let chip = CGPoint(x: 300, y: 1500)

  func spark(_ index: Int, at elapsed: Double) -> FinishCheer.Spark? {
    FinishCheer.spark(index, at: elapsed, from: word, to: chip, reach: 40)
  }

  @Test func nothingMovesUntilThePanHasSettled() {
    #expect(FinishCheer.wordScale(at: 0) == 1)
    #expect(FinishCheer.wordScale(at: nil) == 1)
    #expect(spark(0, at: FinishCheer.start - 0.01) == nil)
    #expect(FinishCheer.chipScale(at: FinishCheer.start) == 1)
  }

  @Test func theWordPopsInPlaceAndSettles() {
    #expect(FinishCheer.wordScale(at: FinishCheer.start + FinishCheer.popSeconds / 2) > 1.2)
    #expect(FinishCheer.wordScale(at: FinishCheer.start + FinishCheer.popSeconds) == 1)
  }

  @Test func starsBurstOutOfTheWord() throws {
    #expect(spark(0, at: FinishCheer.start)?.centre == word)
    let burst = try #require(spark(2, at: FinishCheer.start + FinishCheer.burstSeconds))
    #expect(hypot(burst.centre.x - word.x, burst.centre.y - word.y) > 39)
    #expect(burst.centre.y < word.y)
  }

  @Test func starsLandOnTheChipThenDisappear() throws {
    let star = try #require(spark(0, at: FinishCheer.firstLanding - 0.0001))
    #expect(hypot(star.centre.x - chip.x, star.centre.y - chip.y) < 2)
    #expect(spark(0, at: FinishCheer.firstLanding + 0.01) == nil)
    #expect(spark(FinishCheer.stars - 1, at: FinishCheer.lastLanding + 0.01) == nil)
  }

  @Test func theChipBumpsWhileTheStarsLand() {
    #expect(FinishCheer.chipScale(at: FinishCheer.firstLanding) == 1)
    #expect(FinishCheer.chipScale(at: (FinishCheer.firstLanding + FinishCheer.end) / 2) > 1.1)
    #expect(FinishCheer.chipScale(at: FinishCheer.end) == 1)
  }

  @Test func theStarCountClimbsAsEachStarLands() {
    #expect(FinishCheer.shownStars(86, at: FinishCheer.start) == 0)
    #expect(FinishCheer.shownStars(86, at: FinishCheer.firstLanding) == 14)
    #expect(FinishCheer.shownStars(86, at: FinishCheer.lastLanding + 0.001) == 86)
    #expect(FinishCheer.shownStars(86, at: nil) == 86)
  }
}
