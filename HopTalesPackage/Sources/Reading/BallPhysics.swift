import CoreGraphics
import Foundation

struct BallPhysics: Equatable {
  struct Pose: Equatable {
    var height: CGFloat
    var scaleX: CGFloat
    var scaleY: CGFloat

    static let resting = Pose(height: 0, scaleX: 1, scaleY: 1)

    static func squashed(by amount: CGFloat) -> Pose {
      Pose(height: 0, scaleX: 1 / (1 - amount), scaleY: 1 - amount)
    }
  }

  enum Segment: Equatable {
    case crouch(TimeInterval)
    case flight(from: CGFloat, apex: CGFloat)
    case contact(speed: CGFloat)
    case rest(TimeInterval)
  }

  struct Jump: Equatable {
    var start: TimeInterval
    var from: CGFloat
  }

  static let idleApex: CGFloat = 26
  static let jumpApex: CGFloat = 46
  static let jumpFlight: TimeInterval = 0.45
  static let gravity = 8 * jumpApex / CGFloat(jumpFlight * jumpFlight)
  static let restitution: CGFloat = 0.45
  static let idlePeriod: TimeInterval = 0.72
  static let anticipation: TimeInterval = 0.07
  static let crouchDepth: CGFloat = 0.14
  static let settle: TimeInterval = 0.12
  static let reducedBob: CGFloat = 2
  static let smallestBounce: CGFloat = 1
  static let referenceSpeed = gravity * CGFloat(jumpFlight / 2)
  static let stretch: CGFloat = 0.12
  static let impactSquash: CGFloat = 0.24

  var idleEpoch: TimeInterval = 0
  var jump: Jump?

  static var idleSegments: [Segment] {
    let hops = bouncing(from: 0, apex: idleApex)
    return hops + [.rest(max(idlePeriod - duration(hops), 0))]
  }

  static func jumpSegments(from height: CGFloat) -> [Segment] {
    let crouch: [Segment] = height > 0 ? [] : [.crouch(anticipation)]
    return crouch + bouncing(from: height, apex: jumpApex) + [.rest(settle)]
  }

  static func bouncing(from height: CGFloat, apex: CGFloat) -> [Segment] {
    var segments: [Segment] = []
    var start = height
    var peak = apex
    while peak >= smallestBounce {
      segments.append(.flight(from: start, apex: peak))
      segments.append(.contact(speed: impactSpeed(apex: peak)))
      start = 0
      peak *= restitution * restitution
    }
    return segments
  }

  static func impactSpeed(apex: CGFloat) -> CGFloat {
    sqrt(2 * gravity * apex)
  }

  static func duration(_ segment: Segment) -> TimeInterval {
    switch segment {
    case let .crouch(time), let .rest(time):
      return time
    case let .flight(from, apex):
      let rising = sqrt(2 * max(apex - from, 0) / gravity)
      let falling = sqrt(2 * apex / gravity)
      return TimeInterval(rising + falling)
    case let .contact(speed):
      return max(0.05 * TimeInterval(min(speed / referenceSpeed, 1.2)), 0.02)
    }
  }

  static func duration(_ segments: [Segment]) -> TimeInterval {
    segments.reduce(0) { $0 + duration($1) }
  }

  static func timeToLanding(from height: CGFloat) -> TimeInterval {
    let segments = jumpSegments(from: height)
    guard let flight = segments.firstIndex(where: {
      if case .flight = $0 { return true }
      return false
    }) else { return 0 }
    return duration(Array(segments[...flight]))
  }

  static func pose(for segment: Segment, at time: TimeInterval) -> Pose {
    switch segment {
    case let .crouch(length):
      return .squashed(by: crouchDepth * CGFloat(sin(.pi * time / length)))
    case .rest:
      return .resting
    case let .contact(speed):
      let length = duration(segment)
      let depth = min(impactSquash * speed / referenceSpeed, 0.28)
      return .squashed(by: depth * CGFloat(sin(.pi * time / length)))
    case let .flight(from, apex):
      let launch = sqrt(2 * gravity * max(apex - from, 0))
      let t = CGFloat(time)
      let height = max(from + launch * t - gravity * t * t / 2, 0)
      let speed = abs(launch - gravity * t)
      let lengthening = 1 + stretch * min(speed / referenceSpeed, 1.25)
      return Pose(height: height, scaleX: 1 / lengthening, scaleY: lengthening)
    }
  }

  static func pose(in segments: [Segment], at time: TimeInterval) -> Pose {
    var remaining = time
    for segment in segments {
      let length = duration(segment)
      if remaining < length { return pose(for: segment, at: remaining) }
      remaining -= length
    }
    return .resting
  }

  func pose(at time: TimeInterval, reduceMotion: Bool = false) -> Pose {
    if reduceMotion {
      let phase = (time - idleEpoch) / Self.idlePeriod
      let bob = Self.reducedBob * CGFloat(0.5 - 0.5 * cos(2 * .pi * phase))
      return Pose(height: bob, scaleX: 1, scaleY: 1)
    }
    if let jump {
      let segments = Self.jumpSegments(from: jump.from)
      let elapsed = time - jump.start
      if elapsed >= 0, elapsed < Self.duration(segments) {
        return Self.pose(in: segments, at: elapsed)
      }
    }
    let cycle = (time - idleEpoch).truncatingRemainder(dividingBy: Self.idlePeriod)
    return Self.pose(in: Self.idleSegments, at: cycle < 0 ? cycle + Self.idlePeriod : cycle)
  }

  mutating func jump(at time: TimeInterval, reduceMotion: Bool = false) {
    guard !reduceMotion else { return }
    let from = pose(at: time).height
    jump = Jump(start: time, from: from)
    idleEpoch = time + Self.duration(Self.jumpSegments(from: from))
  }
}
