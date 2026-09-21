import SwiftUI

/// Colour tokens from `HANDOFF.md` §3.
///
/// All chrome (card, chips, pills, buttons) is cream on every stage. Chrome never changes with
/// time of day — only the world does.
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
