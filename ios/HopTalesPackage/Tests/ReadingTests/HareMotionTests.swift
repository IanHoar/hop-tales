import Foundation
import Testing
import World

@testable import Reading

struct HareMotionTests {
  @Test func theHopPlaysEightFramesAtFourteenFramesASecond() {
    var motion = HareMotion()
    let length = motion.jump(at: 10, distance: 80, carried: false)
    #expect(abs(length - 8.0 / 14) < 0.0001)
    let frames = (0..<8).map { step in
      motion.pose(at: 10 + (Double(step) + 0.5) / 14, reduceMotion: false).frame
    }
    #expect(frames == (0..<8).map { HareFrame(.hop, $0) })
    #expect(motion.pose(at: 10 + length + 0.01, reduceMotion: false).frame.sheet == .idle)
  }

  @Test func heOnlyTravelsDuringTheSecondToSeventhFrames() {
    var motion = HareMotion()
    motion.jump(at: 0, distance: 80, carried: false)
    #expect(motion.x(at: 0.5 / 14) == 0)
    #expect(motion.x(at: 1.0 / 14) == 0)
    #expect(motion.x(at: 4.0 / 14) > 0)
    #expect(abs(motion.x(at: 7.0 / 14) - 80) < 0.0001)
    #expect(abs(motion.x(at: 7.9 / 14) - 80) < 0.0001)
  }

  @Test func heLeavesTheCardInAnArcAndLandsOnIt() {
    var motion = HareMotion()
    motion.jump(at: 0, distance: 80, carried: false)
    #expect(motion.lift(at: 1.0 / 14) == 0)
    #expect(abs(motion.lift(at: 4.0 / 14) - HareMotion.apex) < 0.0001)
    #expect(motion.lift(at: 7.0 / 14) == 0)
  }

  @Test func aNewSentenceIsABiggerJump() {
    var motion = HareMotion()
    motion.jump(at: 0, distance: 400, carried: true)
    #expect(abs(motion.lift(at: 4.0 / 14) - HareMotion.sentenceApex) < 0.0001)
    #expect(HareMotion.sentenceApex > HareMotion.apex)
    #expect(abs(HareMotion.takeOff + HareMotion.airTime - 7.0 / 14) < 0.0001)
  }

  @Test func aWordReadMidHopLandsOnThatWordWithoutOvershooting() {
    var motion = HareMotion()
    motion.jump(at: 0, distance: 80, carried: false)
    let length = motion.jump(at: 4.0 / 14, distance: 150, carried: false)
    let landing = 4.0 / 14 + length
    #expect(abs(motion.x(at: landing - 0.001) - 150) < 0.5)
  }

  @Test func fastReadingSpeedsTheHopsUpAndCalmsDownAfter() {
    var motion = HareMotion()
    let first = motion.jump(at: 0, distance: 80, carried: false)
    let second = motion.jump(at: 0.1, distance: 160, carried: false)
    let third = motion.jump(at: 0.2, distance: 240, carried: false)
    #expect(second < first)
    #expect(third < second)
    for step in 1...10 {
      motion.jump(at: 0.2 + Double(step) * 0.05, distance: 300, carried: false)
    }
    #expect(motion.hop?.rate == HareMotion.fastestRate)
    let calm = motion.jump(at: 10, distance: 60, carried: false)
    #expect(abs(calm - first) < 0.0001)
  }

  @Test func afterLandingHeRidesTheWordsBackToTheCentre() {
    var motion = HareMotion()
    let landing = motion.jump(at: 0, distance: 80, carried: false)
    #expect(motion.x(at: landing + HareMotion.ride / 2) < 80)
    #expect(motion.x(at: landing + HareMotion.ride) == 0)
  }

  @Test func aWordReadMidHopSetsOffFromWhereHeIs() {
    var motion = HareMotion()
    motion.jump(at: 0, distance: 80, carried: false)
    let midway = motion.x(at: 4.0 / 14)
    motion.jump(at: 4.0 / 14, distance: 60, carried: false)
    #expect(motion.hop?.fromX == midway)
  }

  @Test func aNewSentenceCarriesHimWithTheCards() {
    var motion = HareMotion()
    motion.jump(at: 0, distance: 400, carried: true)
    #expect(motion.x(at: 4.0 / 14) == 0)
    #expect(motion.pose(at: 4.0 / 14, reduceMotion: false).frame.sheet == .hop)
  }

  @Test func reduceMotionHoldsTheRestingPose() {
    var motion = HareMotion()
    motion.jump(at: 0, distance: 80, carried: false)
    #expect(motion.pose(at: 0.2, reduceMotion: true) == .resting)
    #expect(motion.pose(at: 30, reduceMotion: true) == .resting)
  }
}
