import CoreGraphics
import DesignSystem
import Foundation
import Testing

@testable import Reading

struct BallPhysicsTests {
  typealias Physics = BallPhysics

  @Test func theIdleCycleIsOneHopAndOneTouchdown() {
    let flight = Physics.duration(.flight(from: 0, apex: Physics.idleApex))
    #expect(abs(Physics.idlePeriod - flight - Physics.contactTime) < 0.0001)
  }

  @Test func theIdleHopReachesItsApexAndNoHigher() {
    let heights = stride(from: 0.0, to: Physics.idlePeriod, by: 0.001).map {
      Physics().pose(at: $0).height
    }
    #expect(abs((heights.max() ?? 0) - Physics.idleApex) < 0.05)
  }

  @Test func theJumpTakesTheSpecTimeAndHeight() {
    let flight = Physics.duration(.flight(from: 0, apex: Physics.jumpApex))
    #expect(abs(flight - Physics.jumpFlight) < 0.0001)
  }

  @Test func everyFlightIsAParabolaUnderOneGravity() {
    let step = 0.01
    for apex in [Physics.idleApex, Physics.jumpApex] {
      let flight = Physics.Segment.flight(from: 0, apex: apex)
      let heights = stride(from: 0.02, to: Physics.duration(flight) - 0.04, by: step).map {
        Physics.pose(for: flight, at: $0).height
      }
      for index in heights.indices.dropFirst().dropLast() {
        let change = heights[index + 1] - 2 * heights[index] + heights[index - 1]
        let acceleration = change / (step * step)
        #expect(abs(acceleration + Physics.gravity) < 1)
      }
    }
  }

  @Test func theIdleHopAndTheJumpFallUnderTheSameGravity() {
    let idle = Physics.duration(.flight(from: 0, apex: Physics.idleApex))
    let jump = Physics.duration(.flight(from: 0, apex: Physics.jumpApex))
    #expect(abs(idle / jump - sqrt(Physics.idleApex / Physics.jumpApex)) < 0.0001)
  }

  @Test func itStretchesRisingAndIsRoundAtTheTop() {
    let flight = Physics.Segment.flight(from: 0, apex: Physics.jumpApex)
    #expect(Physics.pose(for: flight, at: 0.01).scaleY > 1.1)
    #expect(abs(Physics.pose(for: flight, at: Physics.jumpFlight / 2).scaleY - 1) < 0.001)
  }

  @Test func aHarderLandingSquashesMore() {
    let hard = Physics.Segment.contact(speed: Physics.impactSpeed(apex: Physics.jumpApex))
    let soft = Physics.Segment.contact(speed: Physics.impactSpeed(apex: Physics.idleApex))
    let hardest = Physics.pose(for: hard, at: Physics.duration(hard) / 2).scaleY
    let softest = Physics.pose(for: soft, at: Physics.duration(soft) / 2).scaleY
    #expect(hardest < softest)
    #expect(softest < 1)
  }

  @Test func theBallKeepsItsVolumeWhenItDeforms() {
    var physics = Physics()
    physics.jump(at: 0, distance: 80)
    for time in stride(from: 0.0, to: 1.5, by: 0.01) {
      let pose = physics.pose(at: time)
      #expect(abs(pose.scaleX * pose.scaleY - 1) < 0.0001)
    }
  }

  @Test func itTakesOffStraightAwayWithoutACrouch() {
    var physics = Physics()
    physics.jump(at: 10, distance: 80)
    #expect(physics.pose(at: 10.02).height > 0)
  }

  @Test func itLandsOnTheNextWordOnceAndThenHopsOn() {
    var physics = Physics()
    let landing = physics.jump(at: 0, distance: 80)
    let touchdown = landing - Physics.contactTime
    #expect(abs(physics.pose(at: touchdown - 0.001).x - 80) < 0.5)
    #expect(physics.pose(at: touchdown + Physics.contactTime / 2).height == 0)
    #expect(physics.idleEpoch == landing)
    let hop = stride(from: landing, to: landing + Physics.idlePeriod, by: 0.01).map {
      physics.pose(at: $0).height
    }
    #expect(abs((hop.max() ?? 0) - Physics.idleApex) < 0.5)
  }

  @Test func itRidesTheWordBackToTheCentreWhileItHops() {
    var physics = Physics()
    let landing = physics.jump(at: 0, distance: 80)
    let riding = stride(from: landing, to: landing + Motion.ride, by: 0.01).map {
      physics.pose(at: $0)
    }
    #expect(riding.contains { $0.height > 0 })
    #expect(zip(riding, riding.dropFirst()).allSatisfy { $1.x <= $0.x + 0.0001 })
    #expect(physics.pose(at: landing + Motion.ride + 0.01).x == 0)
  }

  @Test func aCarriedJumpLandsInTheCentreWithoutRiding() {
    var physics = Physics()
    let landing = physics.jump(at: 0, distance: 400, carried: true)
    let flight = stride(from: 0.0, to: landing, by: 0.01).map { physics.pose(at: $0).x }
    #expect(flight.allSatisfy { abs($0) < 400 * 0.2 })
    #expect(physics.pose(at: landing - 0.001).x == 0)
    #expect(physics.pose(at: landing + 0.1).x == 0)
  }

  @Test func aWordReadMidAirLaunchesFromWhereTheBallIs() {
    var physics = Physics()
    physics.jump(at: 0, distance: 80)
    let before = physics.pose(at: 0.2)
    #expect(before.height > 0)
    physics.jump(at: 0.2, distance: 150)
    let after = physics.pose(at: 0.2)
    #expect(abs(after.height - before.height) < 0.0001)
    #expect(abs(after.x - before.x) < 0.0001)
  }

  @Test func theTrailOnlyFollowsTheFlight() {
    var physics = Physics()
    #expect(physics.trail(at: 0.2, count: 4, spacing: 0.03).allSatisfy { $0 == nil })
    let landing = physics.jump(at: 1, distance: 80)
    #expect(physics.trail(at: 1.2, count: 4, spacing: 0.03).allSatisfy { $0 != nil })
    #expect(physics.trail(at: 1 + landing + 0.3, count: 4, spacing: 0.03).allSatisfy { $0 == nil })
  }

  @Test func reduceMotionIsAGentleBobThatNeverSquashes() {
    let physics = Physics()
    for time in stride(from: 0.0, through: 0.72, by: 0.04) {
      let pose = physics.pose(at: time, reduceMotion: true)
      #expect(pose.scaleX == 1)
      #expect(pose.scaleY == 1)
      #expect(pose.height <= Physics.reducedBob + 0.0001)
    }
  }
}
