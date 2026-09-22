import DesignSystem
import SwiftUI

struct BallPhysics: Equatable {
  struct Pose: Equatable {
    var x: CGFloat = 0
    var height: CGFloat
    var scaleX: CGFloat
    var scaleY: CGFloat

    static let resting = Pose(height: 0, scaleX: 1, scaleY: 1)

    static func squashed(by amount: CGFloat) -> Pose {
      Pose(height: 0, scaleX: 1 / (1 - amount), scaleY: 1 - amount)
    }
  }

  enum Segment: Equatable {
    case flight(from: CGFloat, apex: CGFloat)
    case contact(speed: CGFloat)
  }

  struct Jump: Equatable {
    var start: TimeInterval
    var from: CGFloat
    var fromX: CGFloat
    var distance: CGFloat
    var carried = false
  }

  static let idleApex: CGFloat = 26
  static let jumpApex: CGFloat = 46
  static let jumpFlight: TimeInterval = 0.6
  static let gravity = 8 * jumpApex / CGFloat(jumpFlight * jumpFlight)
  static let contactTime: TimeInterval = 0.07
  static let reducedBob: CGFloat = 2
  static let reducedPeriod: TimeInterval = 0.72
  static let referenceSpeed = gravity * CGFloat(jumpFlight / 2)
  static let stretch: CGFloat = 0.12
  static let impactSquash: CGFloat = 0.24

  var idleEpoch: TimeInterval = 0
  var jump: Jump?

  static var idleSegments: [Segment] {
    [.flight(from: 0, apex: idleApex), .contact(speed: impactSpeed(apex: idleApex))]
  }

  static var idlePeriod: TimeInterval { duration(idleSegments) }

  static func jumpSegments(from height: CGFloat) -> [Segment] {
    [
      .flight(from: height, apex: jumpApex),
      .contact(speed: impactSpeed(apex: jumpApex))
    ]
  }

  static func landing(from height: CGFloat) -> TimeInterval {
    duration(jumpSegments(from: height))
  }

  static func impactSpeed(apex: CGFloat) -> CGFloat {
    sqrt(2 * gravity * apex)
  }

  static func duration(_ segment: Segment) -> TimeInterval {
    switch segment {
    case let .flight(from, apex):
      let rising = sqrt(2 * max(apex - from, 0) / gravity)
      let falling = sqrt(2 * apex / gravity)
      return TimeInterval(rising + falling)
    case .contact:
      return contactTime
    }
  }

  static func duration(_ segments: [Segment]) -> TimeInterval {
    segments.reduce(0) { $0 + duration($1) }
  }

  static func pose(for segment: Segment, at time: TimeInterval) -> Pose {
    switch segment {
    case let .contact(speed):
      let depth = min(impactSquash * speed / referenceSpeed, 0.28)
      return .squashed(by: depth * CGFloat(sin(.pi * time / contactTime)))
    case let .flight(from, apex):
      let launch = sqrt(2 * gravity * max(apex - from, 0))
      let t = CGFloat(time)
      let height = max(from + launch * t - gravity * t * t / 2, 0)
      let speed = abs(launch - gravity * t)
      let lengthening = 1 + stretch * min(speed / referenceSpeed, 1.25)
      return Pose(height: height, scaleX: 1 / lengthening, scaleY: lengthening)
    }
  }

  static func locate(
    in segments: [Segment],
    at time: TimeInterval
  ) -> (segment: Segment, elapsed: TimeInterval)? {
    var remaining = time
    for segment in segments {
      let length = duration(segment)
      if remaining < length { return (segment, remaining) }
      remaining -= length
    }
    return nil
  }

  private func jumpPose(at time: TimeInterval) -> Pose? {
    guard let jump else { return nil }
    let elapsed = time - jump.start
    guard elapsed >= 0,
      let (segment, into) = Self.locate(in: Self.jumpSegments(from: jump.from), at: elapsed)
    else { return nil }
    var pose = Self.pose(for: segment, at: into)
    switch segment {
    case .flight:
      let progress = into / Self.duration(segment)
      let ground = jump.carried ? jump.distance * CGFloat(Motion.rideCurve.value(at: progress)) : 0
      pose.x = jump.fromX + (jump.distance - jump.fromX) * CGFloat(progress) - ground
    case .contact:
      pose.x = jump.carried ? 0 : jump.distance
    }
    return pose
  }

  private func rideOffset(at time: TimeInterval) -> CGFloat {
    guard let jump, !jump.carried else { return 0 }
    let riding = time - idleEpoch
    guard riding >= 0, riding < Motion.ride else { return 0 }
    return jump.distance * (1 - CGFloat(Motion.rideCurve.value(at: riding / Motion.ride)))
  }

  func isFlying(at time: TimeInterval) -> Bool {
    guard let jump else { return false }
    let elapsed = time - jump.start
    return elapsed >= 0 && elapsed < Self.duration(.flight(from: jump.from, apex: Self.jumpApex))
  }

  func pose(at time: TimeInterval, reduceMotion: Bool = false) -> Pose {
    if reduceMotion {
      let phase = (time - idleEpoch) / Self.reducedPeriod
      let bob = Self.reducedBob * CGFloat(0.5 - 0.5 * cos(2 * .pi * phase))
      return Pose(height: bob, scaleX: 1, scaleY: 1)
    }
    if let pose = jumpPose(at: time) { return pose }
    let cycle = (time - idleEpoch).truncatingRemainder(dividingBy: Self.idlePeriod)
    let phase = cycle < 0 ? cycle + Self.idlePeriod : cycle
    guard let (segment, elapsed) = Self.locate(in: Self.idleSegments, at: phase) else {
      return .resting
    }
    var pose = Self.pose(for: segment, at: elapsed)
    pose.x = rideOffset(at: time)
    return pose
  }

  func trail(at time: TimeInterval, count: Int, spacing: TimeInterval) -> [Pose?] {
    (1...count).map { step in
      let past = time - Double(step) * spacing
      return isFlying(at: past) ? pose(at: past) : nil
    }
  }

  @discardableResult
  mutating func jump(
    at time: TimeInterval,
    distance: CGFloat = 0,
    carried: Bool = false
  ) -> TimeInterval {
    let now = pose(at: time)
    jump = Jump(start: time, from: now.height, fromX: now.x, distance: distance, carried: carried)
    idleEpoch = time + Self.duration(Self.jumpSegments(from: now.height))
    return Self.landing(from: now.height)
  }
}
