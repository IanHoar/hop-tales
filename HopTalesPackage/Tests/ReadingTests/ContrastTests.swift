import DesignSystem
import SwiftUI
import Testing
import UIKit

enum Contrast {
  static func luminance(_ color: Color, style: UIUserInterfaceStyle = .light) -> Double {
    let traits = UITraitCollection(userInterfaceStyle: style)
    let color = Color(UIColor(color).resolvedColor(with: traits))
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    func channel(_ value: CGFloat) -> Double {
      let value = Double(value)
      return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
  }

  static func ratio(
    _ foreground: Color,
    on background: Color,
    style: UIUserInterfaceStyle = .light
  ) -> Double {
    let first = luminance(foreground, style: style)
    let second = luminance(background, style: style)
    return (max(first, second) + 0.05) / (min(first, second) + 0.05)
  }
}

@MainActor
struct ContrastTests {
  static let floor = 4.5
  static let largeTextFloor = 3.0
  nonisolated static let styles: [UIUserInterfaceStyle] = [.light, .dark]

  @Test(arguments: styles)
  func readingTextClearsTheFloorOnParchment(style: UIUserInterfaceStyle) {
    #expect(Contrast.ratio(Palette.ink, on: Palette.parchment, style: style) >= Self.floor)
    #expect(Contrast.ratio(Palette.muted, on: Palette.parchment, style: style) >= Self.floor)
    #expect(Contrast.ratio(Palette.ink, on: Palette.page, style: style) >= Self.floor)
    #expect(Contrast.ratio(Palette.muted, on: Palette.page, style: style) >= Self.floor)
  }

  @Test(arguments: styles)
  func theWordAfterNextClearsTheLargeTextFloor(style: UIUserInterfaceStyle) {
    let ratio = Contrast.ratio(Palette.faint, on: Palette.parchment, style: style)
    #expect(ratio >= Self.largeTextFloor)
  }

  @Test(arguments: styles)
  func pillsAndAccentsClearTheFloor(style: UIUserInterfaceStyle) {
    #expect(Contrast.ratio(Palette.pillText, on: Palette.goldLight, style: style) >= Self.floor)
    #expect(Contrast.ratio(Palette.onAccent, on: Palette.gold, style: style) >= Self.floor)
    #expect(Contrast.ratio(Palette.heardText, on: Palette.heardBg, style: style) >= Self.floor)
    #expect(Contrast.ratio(Palette.ink, on: Palette.paper, style: style) >= Self.floor)
  }

  @Test(arguments: styles)
  func parchmentOnTealClearsTheLargeTextFloor(style: UIUserInterfaceStyle) {
    #expect(Contrast.ratio(Palette.onTeal, on: Palette.teal, style: style) >= Self.largeTextFloor)
  }
}
