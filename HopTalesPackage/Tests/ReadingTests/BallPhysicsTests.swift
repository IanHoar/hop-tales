import CoreGraphics
import Foundation
import Testing

@testable import Reading

struct BallPhysicsTests {
  typealias Physics = BallPhysics

  func peaks(of segments: [Physics.Segment]) -> [CGFloat] {
    segments.compactMap {
      if case let .flight(_, apex) = $0 { return apex }
      return nil
    }
  }

  @Test func theIdleCycleKeepsTheSpecPeriod() {
    #expect(abs(Physics.duration(Physics.idleSegments) - 0.72) < 0.0001)
  }

  @Test func theIdleHopReachesItsApexAndNoHigher() {
    let heights = stride(from: 0.0, to: 0.72, by: 0.001).map { Physics().pose(at: $0).height }
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

  @Test func eachBounceLosesTheSameShareOfItsHeight() {
    let bounces = peaks(of: Physics.jumpSegments(from: 0))
    #expect(bounces.count >= 3)
    for pair in zip(bounces, bounces.dropFirst()) {
      #expect(abs(pair.1 / pair.0 - Physics.restitution * Physics.restitution) < 0.0001)
    }
  }

  @Test func itCrouchesOnTheGroundBeforeItJumps() {
    var physics = Physics()
    physics.jump(at: 10)
    let crouching = physics.pose(at: 10 + Physics.anticipation / 2)
    #expect(crouching.height == 0)
    #expect(crouching.scaleY < 1)
    #expect(crouching.scaleX > 1)
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
    physics.jump(at: 0)
    for time in stride(from: 0.0, to: 1.0, by: 0.01) {
      let pose = physics.pose(at: time)
      #expect(abs(pose.scaleX * pose.scaleY - 1) < 0.0001)
    }
  }

  @Test func aWordReadMidAirLaunchesFromWhereTheBallIs() {
    var physics = Physics()
    let midHop = 0.1
    let before = physics.pose(at: midHop).height
    #expect(before > 0)
    physics.jump(at: midHop)
    #expect(abs(physics.pose(at: midHop).height - before) < 0.0001)
  }

  @Test func itComesToRestAndGoesBackToHopping() {
    var physics = Physics()
    physics.jump(at: 0)
    let settled = Physics.duration(Physics.jumpSegments(from: 0))
    #expect(physics.pose(at: settled - 0.001) == .resting)
    #expect(physics.idleEpoch == settled)
    #expect(physics.pose(at: settled + 0.1).height > 0)
  }

  @Test func theWordsSlideWhileTheBallIsInTheAir() {
    var physics = Physics()
    physics.jump(at: 0)
    #expect(physics.pose(at: Physics.anticipation - 0.001).height == 0)
    #expect(physics.pose(at: Physics.anticipation + 0.01).height > 0)
    #expect(Physics.anticipation == 0.07)
    #expect(Physics.jumpFlight == 0.45)
  }

  @Test func reduceMotionIsAGentleBobThatNeverSquashes() {
    var physics = Physics()
    physics.jump(at: 0, reduceMotion: true)
    #expect(physics.jump == nil)
    for time in stride(from: 0.0, through: 0.72, by: 0.04) {
      let pose = physics.pose(at: time, reduceMotion: true)
      #expect(pose.scaleX == 1)
      #expect(pose.scaleY == 1)
      #expect(pose.height <= Physics.reducedBob + 0.0001)
    }
  }
}
