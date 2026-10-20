import SwiftUI
import UIKit

public enum Palette {
  public static let outline = Color(light: 0x1D1A2C, dark: 0x07060D)
  public static let ink = Color(light: 0x1D1A2C, dark: 0xFFF3D6)
  public static let parchment = Color(light: 0xFFF6E2, dark: 0x2E2844)
  public static let parchmentLip = Color(light: 0xEBD5A6, dark: 0x1C1729)
  public static let paper = Color(light: 0xFFFBF1, dark: 0x352E4E)
  public static let page = Color(light: 0xF7E9C8, dark: 0x1B1728)
  public static let highlight = Color(
    light: 0xFFFFFF,
    dark: 0xFFFFFF,
    lightOpacity: 0.85,
    darkOpacity: 0.16
  )

  public static let red = Color(hex: 0xDB2A2E)
  public static let gold = Color(hex: 0xF6BB3E)
  public static let goldShade = Color(hex: 0xC7861A)
  public static let goldLight = Color(hex: 0xFFE39A)
  public static let teal = Color(hex: 0x1E8C8C)
  public static let tealShade = Color(hex: 0x136066)
  public static let onAccent = Color(hex: 0x1D1A2C)
  public static let onTeal = Color(hex: 0xFFF6E2)

  public static let pillText = Color(hex: 0x7A4A0C)
  public static let muted = Color(light: 0x665F78, dark: 0xB9B2CB)
  public static let faint = Color(light: 0x8A8499, dark: 0x918AA6)
  public static let heardBg = Color(light: 0xE4F6D2, dark: 0x27402A)
  public static let heardText = Color(light: 0x1D1A2C, dark: 0xE4F6D2)
  public static let done = Color(hex: 0x8BD06A)
  public static let duskRoot = Color(hex: 0x1B1738)

  public static let amberDeep = goldShade
  public static let cream = parchment
}

extension Color {
  public init(hex: UInt32, opacity: Double = 1) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: opacity
    )
  }

  public init(light: UInt32, dark: UInt32, lightOpacity: Double = 1, darkOpacity: Double = 1) {
    self.init(
      uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
          ? UIColor(hex: dark, alpha: darkOpacity)
          : UIColor(hex: light, alpha: lightOpacity)
      }
    )
  }
}

extension UIColor {
  convenience init(hex: UInt32, alpha: Double = 1) {
    self.init(
      red: CGFloat((hex >> 16) & 0xFF) / 255,
      green: CGFloat((hex >> 8) & 0xFF) / 255,
      blue: CGFloat(hex & 0xFF) / 255,
      alpha: alpha
    )
  }
}

extension Palette {
}
