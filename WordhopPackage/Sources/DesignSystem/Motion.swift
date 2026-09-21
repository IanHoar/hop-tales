import SwiftUI

/// Motion tokens from `HANDOFF.md` §4.
///
/// `Design/artboards/Parallax.dc.html` is the acceptance test for how this should feel.
public enum Motion {
  /// translateY 0 → −26, autoreversing, forever.
  public static let idleHop = Animation
    .timingCurve(0.3, 0, 0.2, 1, duration: 0.72)
    .repeatForever(autoreverses: true)

  /// Ball arcs to the next word while the current word morphs to a pill and the row slides left.
  public static let recognised = Animation.easeInOut(duration: 0.45)

  /// World layers easing to a new progress value — easeOutExpo.
  public static let world = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.6)

  public static let ballApexIdle: CGFloat = -26
  public static let ballApexRecognised: CGFloat = -46

  /// Reduce Motion: the hop becomes a 2pt bob, sparkles are dropped, world layers cut.
  public static let reducedHopOffset: CGFloat = -2
}
