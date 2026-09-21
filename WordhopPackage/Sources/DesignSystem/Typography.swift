import SwiftUI

/// Type tokens from `HANDOFF.md` §3.
///
/// Andika carries the reading surface (it is a literacy face: single-storey *a* and *g*), Fredoka
/// carries the chrome. Both are SIL Open Font License and are expected to be bundled with the app
/// target; until they are, `Font.custom` falls back to the system face at the same size.
public enum Typography {
  public enum Family {
    public static let word = "Andika"
    public static let ui = "Fredoka"
  }

  /// Sizes are fixed by design — Dynamic Type is deliberately not applied to the word track.
  public static func word(_ size: CGFloat) -> Font {
    .custom(Family.word, fixedSize: size)
  }

  public static func ui(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
    .custom(Family.ui, size: size, relativeTo: style)
  }

  /// Caps labels (`SENTENCE 2 OF 6`) — tracking is applied at the call site with `.tracking`.
  public static func caps(_ size: CGFloat) -> Font {
    .custom(Family.ui, fixedSize: size)
  }
}
