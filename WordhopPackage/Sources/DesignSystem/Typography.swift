import SwiftUI
import UIKit

/// Type tokens from `docs/HANDOFF.md` §3.
///
/// Andika carries the reading surface (it is a literacy face: single-storey *a* and *g*), Fredoka
/// carries the chrome. Both are SIL Open Font License and are expected to be bundled with the app
/// target; until they are, this falls back to the system face at the same size and weight.
public enum Typography {
  public enum Family {
    public static let word = "Andika"
    public static let ui = "Fredoka"
  }

  /// Sizes are fixed by design — Dynamic Type is deliberately not applied to the word track.
  public static func word(_ size: CGFloat) -> Font {
    .custom(Family.word, fixedSize: size).weight(.bold)
  }

  public static func ui(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
    .custom(Family.ui, size: size, relativeTo: style)
  }

  /// Caps labels (`SENTENCE 2 OF 6`) — tracking is applied at the call site with `.tracking`.
  public static func caps(_ size: CGFloat) -> Font {
    .custom(Family.ui, fixedSize: size)
  }

  /// The word face as a `UIFont`, for measuring text before it is laid out.
  public static func wordUIFont(_ size: CGFloat) -> UIFont {
    UIFont(name: "\(Family.word)-Bold", size: size)
      ?? UIFont(name: Family.word, size: size)
      ?? .systemFont(ofSize: size, weight: .bold)
  }

  /// Tracking for the current word: −0.01em on phone and iPad, −0.015em on TV.
  public static func wordTracking(_ size: CGFloat, em: CGFloat = -0.01) -> CGFloat {
    size * em
  }

  public static func width(of text: String, size: CGFloat, tracking: CGFloat = 0) -> CGFloat {
    let attributes: [NSAttributedString.Key: Any] = [
      .font: wordUIFont(size),
      .kern: tracking,
    ]
    return ceil(NSAttributedString(string: text, attributes: attributes).size().width)
  }
}
