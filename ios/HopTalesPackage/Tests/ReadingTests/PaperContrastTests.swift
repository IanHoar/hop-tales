import DesignSystem
import SwiftUI
import Testing
import UIKit

@MainActor
struct PaperContrastTests {
  nonisolated static let styles: [UIUserInterfaceStyle] = [.light, .dark]

  static func storyRow(_ style: UIUserInterfaceStyle) -> Color {
    Contrast.composite(Paper.rim, opacity: 0.55, over: Paper.paper, style: style)
  }

  @Test(arguments: styles)
  func inkReadsOnEveryPaperSurface(style: UIUserInterfaceStyle) {
    let row = Self.storyRow(style)
    let surfaces = [Paper.paper, Paper.page, Paper.shade, Paper.wash, Paper.rim, row]
    for surface in surfaces {
      #expect(Contrast.ratio(Paper.ink, on: surface, style: style) >= ContrastTests.floor)
    }
  }

  @Test(arguments: styles)
  func mutedTextReadsOnEveryPaperSurface(style: UIUserInterfaceStyle) {
    for surface in [Paper.paper, Paper.page, Paper.shade, Paper.rim, Self.storyRow(style)] {
      #expect(Contrast.ratio(Paper.muted, on: surface, style: style) >= ContrastTests.floor)
    }
  }

  @Test(arguments: styles)
  func theNewLabelReadsOnAStoryRow(style: UIUserInterfaceStyle) {
    #expect(
      Contrast.ratio(Paper.redInk, on: Self.storyRow(style), style: style) >= ContrastTests.floor
    )
  }

  @Test(arguments: styles)
  func theRedButtonLabelReads(style: UIUserInterfaceStyle) {
    #expect(Contrast.ratio(Paper.onRed, on: Paper.red, style: style) >= ContrastTests.floor)
  }
}
