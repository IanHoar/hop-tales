import SwiftUI

public enum Motion {
  public static let recognised = Animation.easeInOut(duration: 0.45)
  public static let ride: TimeInterval = 0.45
  public static let rideCurve = UnitCurve.easeInOut
  public static let slide = Animation.timingCurve(rideCurve, duration: ride)
}
