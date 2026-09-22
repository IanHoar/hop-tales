import DesignSystem
import SwiftUI
import Testing
import UIKit

enum Contrast {
  static func luminance(_ color: Color) -> Double {
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

  static func ratio(_ foreground: Color, on background: Color) -> Double {
    let first = luminance(foreground)
    let second = luminance(background)
    return (max(first, second) + 0.05) / (min(first, second) + 0.05)
  }
}

@MainActor
struct ContrastTests {
  static let floor = 4.5

  @Test func theCurrentAndNextWordsClearTheFloorOnCream() {
    #expect(Contrast.ratio(Palette.ink, on: Palette.cream) >= Self.floor)
    #expect(Contrast.ratio(Palette.muted, on: Palette.cream) >= Self.floor)
    #expect(Contrast.ratio(Palette.chipText, on: Palette.cream) >= Self.floor)
  }

  @Test func thePillsClearTheFloorAgainstTheirOwnBackgrounds() {
    #expect(Contrast.ratio(Palette.pillText, on: Palette.pillBg) >= Self.floor)
    #expect(Contrast.ratio(Palette.flashText, on: Palette.amber) >= Self.floor)
    #expect(Contrast.ratio(Palette.heardText, on: Palette.heardBg) >= Self.floor)
  }

  @Test func upcomingWordsDoNotClearTheFloor() {
    withKnownIssue(
      """
      faint on cream is 2.78:1 where HANDOFF §9 asks for 4.5:1. Darkening it to #776F86 passes at \
      4.52:1 but lands on top of muted (5.08:1), so upcoming and next words stop being \
      distinguishable and the word track loses its depth cue. Whether the rule or the palette \
      gives is a design decision.
      """
    ) {
      #expect(Contrast.ratio(Palette.faint, on: Palette.cream) >= Self.floor)
    }
  }
}
