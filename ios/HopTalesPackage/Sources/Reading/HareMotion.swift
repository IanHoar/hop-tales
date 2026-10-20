import Foundation
import World

struct HareMotion: Equatable {
  struct Pose: Equatable {
    var frame: HareFrame
    var x: CGFloat = 0
    var lift: CGFloat = 0
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1

    static let resting = Pose(frame: .rest)
  }

  struct Hop: Equatable {
    var start: TimeInterval
    var fromX: CGFloat
    var distance: CGFloat
    var carried = false
    var rate: Double = 1

    var frameTime: TimeInterval { 1 / (HareMotion.fps * rate) }
    var length: TimeInterval { Double(HareMotion.hopFrames) * frameTime }
    var takeOff: TimeInterval { Double(HareMotion.moveFrames.lowerBound) * frameTime }
    var airTime: TimeInterval { Double(HareMotion.moveFrames.count) * frameTime }
  }

  static let fps: Double = 14
  static let hopFrames = 8
  static let moveFrames = 1...6
  static let ride: TimeInterval = 0.45
  static let apex: CGFloat = 46
  static let sentenceApex: CGFloat = 96
  static let rateStep: Double = 0.6
  static let fastestRate: Double = 2.2
  static let takeOff = Double(moveFrames.lowerBound) / fps
  static let airTime = Double(moveFrames.count) / fps

  var hop: Hop?

  static func eased(_ progress: Double) -> CGFloat {
    let clamped = min(max(progress, 0), 1)
    return CGFloat(clamped * clamped * (3 - 2 * clamped))
  }

  func x(at time: TimeInterval) -> CGFloat {
    guard let hop, !hop.carried else { return 0 }
    let elapsed = time - hop.start
    if elapsed < hop.length {
      let progress = Self.eased((elapsed - hop.takeOff) / hop.airTime)
      return hop.fromX + (hop.distance - hop.fromX) * progress
    }
    return hop.distance * (1 - Self.eased((elapsed - hop.length) / Self.ride))
  }

  func isAirborne(at time: TimeInterval) -> Bool {
    guard let hop else { return false }
    return time >= hop.start && time - hop.start < hop.length
  }

  func arc(at time: TimeInterval) -> CGFloat {
    guard let hop else { return 0 }
    let progress = (time - hop.start - hop.takeOff) / hop.airTime
    guard progress > 0, progress < 1 else { return 0 }
    return CGFloat(sin(.pi * progress))
  }

  func lift(at time: TimeInterval) -> CGFloat {
    guard let hop else { return 0 }
    return (hop.carried ? Self.sentenceApex : Self.apex) * arc(at: time)
  }

  func pose(at time: TimeInterval, reduceMotion: Bool) -> Pose {
    guard !reduceMotion else { return .resting }
    if let hop, isAirborne(at: time) {
      let index = min(Int((time - hop.start) / hop.frameTime), Self.hopFrames - 1)
      return Pose(frame: HareFrame(.hop, index), x: x(at: time), lift: lift(at: time))
    }
    let breath = IdleMotion.breathing(at: time)
    return Pose(
      frame: HareFrame(.idle, IdleMotion.frame(at: time)),
      x: x(at: time),
      scaleX: breath.x,
      scaleY: breath.y
    )
  }

  @discardableResult
  mutating func jump(at time: TimeInterval, distance: CGFloat, carried: Bool) -> TimeInterval {
    let chained = !carried && isAirborne(at: time)
    let next = Hop(
      start: time,
      fromX: carried ? 0 : x(at: time),
      distance: distance,
      carried: carried,
      rate: chained ? min((hop?.rate ?? 1) + Self.rateStep, Self.fastestRate) : 1
    )
    hop = next
    return next.length
  }
}
