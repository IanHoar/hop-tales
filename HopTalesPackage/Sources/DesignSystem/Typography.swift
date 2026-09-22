import SwiftUI
import UIKit

public enum Typography {
  public enum Family {
    public static let word = "Andika"
    public static let ui = "Fredoka"
  }

  public static func word(_ size: CGFloat) -> Font {
    .custom(Family.word, fixedSize: size).weight(.bold)
  }

  public static func ui(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
    .custom(Family.ui, size: size, relativeTo: style)
  }

  public static func caps(_ size: CGFloat) -> Font {
    .custom(Family.ui, fixedSize: size)
  }

  public static func wordUIFont(_ size: CGFloat) -> UIFont {
    UIFont(name: "\(Family.word)-Bold", size: size)
      ?? UIFont(name: Family.word, size: size)
      ?? .systemFont(ofSize: size, weight: .bold)
  }

  public static func wordTracking(_ size: CGFloat, em: CGFloat = -0.01) -> CGFloat {
    size * em
  }

  public static func width(of text: String, size: CGFloat, tracking: CGFloat = 0) -> CGFloat {
    let attributes: [NSAttributedString.Key: Any] = [
      .font: wordUIFont(size),
      .kern: tracking
    ]
    return ceil(NSAttributedString(string: text, attributes: attributes).size().width)
  }
}
