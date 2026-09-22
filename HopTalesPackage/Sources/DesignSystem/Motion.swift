import SwiftUI

public enum Motion {
  public static let idleHopPeriod: TimeInterval = 0.72
  public static let recognised = Animation.easeInOut(duration: 0.45)
  public static let anticipation: TimeInterval = 0.07
  public static let flight: TimeInterval = 0.45
  public static let slide = Animation.linear(duration: flight).delay(anticipation)
  public static let world = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.6)
  public static let ballApexIdle: CGFloat = -26
  public static let ballApexRecognised: CGFloat = -46
  public static let reducedHopOffset: CGFloat = -2
}
