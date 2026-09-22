import SwiftUI

public enum Palette {
  public static let amber = Color(hex: 0xFFB23F)
  public static let amberDeep = Color(hex: 0xE07A22)
  public static let ball = Color(hex: 0xFFA552)
  public static let ballHi = Color(hex: 0xFFD9A8)
  public static let ballLo = Color(hex: 0xD96A1B)
  public static let chipText = Color(hex: 0x5C5670)
  public static let cream = Color(hex: 0xFFF8EC)
  public static let creamDeep = Color(hex: 0xFFF1D4)
  public static let duskRoot = Color(hex: 0x1B1738)
  public static let faint = Color(hex: 0x9A94A6)
  public static let flashText = Color(hex: 0x4A2D05)
  public static let heardBg = Color(hex: 0xDCF0CE)
  public static let heardText = Color(hex: 0x34601F)
  public static let ink = Color(hex: 0x2E2A3B)
  public static let listenBars = Color(hex: 0x7CBA63)
  public static let muted = Color(hex: 0x6E6780)
  public static let pillBg = Color(hex: 0xFFE0A8)
  public static let pillText = Color(hex: 0x8A5A12)
  public static let newBadgeBg = Color(hex: 0xF0E4FB)
  public static let newBadgeText = Color(hex: 0x5B3D8C)
  public static let railLabel = Color(hex: 0x2E4A2E)
  public static let starText = Color(hex: 0xB4701A)
  public static let surfaceMuted = Color(hex: 0xF1E8D8)
  public static let trackBg = Color(hex: 0xEFE7DA)
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
}

extension Palette {
  public enum SceneShadow {
    public static let meadow = Color(hex: 0x1E3A20)
    public static let castle = Color(hex: 0x5A3A16)
    public static let dusk = Color(hex: 0x000000)
  }
}
