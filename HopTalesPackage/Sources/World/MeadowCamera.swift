import QuartzCore
import SwiftUI

public struct MeadowCamera: Hashable, Sendable {
  public static let curve = UnitCurve.bezier(
    startControlPoint: UnitPoint(x: 0.45, y: 0),
    endControlPoint: UnitPoint(x: 0.3, y: 1)
  )

  public var from: CGFloat
  public var to: CGFloat
  public var start: TimeInterval
  public var duration: TimeInterval

  public init(at x: CGFloat) {
    from = x
    to = x
    start = 0
    duration = 0
  }

  public static var now: TimeInterval { CACurrentMediaTime() }

  public func x(at time: TimeInterval) -> CGFloat {
    guard duration > 0 else { return to }
    let progress = min(max((time - start) / duration, 0), 1)
    return from + (to - from) * CGFloat(Self.curve.value(at: progress))
  }

  public func panning(
    to target: CGFloat,
    at time: TimeInterval,
    over duration: TimeInterval
  ) -> MeadowCamera {
    var next = self
    next.from = x(at: time)
    next.to = target
    next.start = time
    next.duration = duration
    return next
  }
}
