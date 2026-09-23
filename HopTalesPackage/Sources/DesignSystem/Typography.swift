import SwiftUI
import UIKit

public enum Typography {
  public enum Face {
    public static let word = "Andika-Bold"
    public static let display = "LilitaOne"
    public static let uiMedium = "Fredoka-Medium"
    public static let uiSemiBold = "Fredoka-SemiBold"
    public static let uiBold = "Fredoka-Bold"
  }

  public enum Weight {
    case medium
    case semibold
    case bold

    var face: String {
      switch self {
      case .medium: Face.uiMedium
      case .semibold: Face.uiSemiBold
      case .bold: Face.uiBold
      }
    }
  }

  public static func word(_ size: CGFloat) -> Font {
    FontRegistry.register()
    return .custom(Face.word, fixedSize: size)
  }

  public static func display(_ size: CGFloat) -> Font {
    FontRegistry.register()
    return .custom(Face.display, fixedSize: size)
  }

  public static func ui(
    _ size: CGFloat,
    weight: Weight = .semibold,
    relativeTo style: Font.TextStyle = .body
  ) -> Font {
    FontRegistry.register()
    return .custom(weight.face, size: size, relativeTo: style)
  }

  public static func caps(_ size: CGFloat) -> Font {
    FontRegistry.register()
    return .custom(Face.uiSemiBold, fixedSize: size)
  }

  public static func wordUIFont(_ size: CGFloat) -> UIFont {
    FontRegistry.register()
    return UIFont(name: Face.word, size: size) ?? .systemFont(ofSize: size, weight: .bold)
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
