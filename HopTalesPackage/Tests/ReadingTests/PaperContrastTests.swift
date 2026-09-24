import DesignSystem
import Testing
import UIKit

@MainActor
struct PaperContrastTests {
  nonisolated static let styles: [UIUserInterfaceStyle] = [.light, .dark]

  @Test(arguments: styles)
  func inkReadsOnEveryPaperSurface(style: UIUserInterfaceStyle) {
    for surface in [Paper.paper, Paper.page, Paper.shade, Paper.wash] {
      #expect(Contrast.ratio(Paper.ink, on: surface, style: style) >= ContrastTests.floor)
    }
  }

  @Test(arguments: styles)
  func mutedWordsClearTheLargeTextFloor(style: UIUserInterfaceStyle) {
    #expect(
      Contrast.ratio(Paper.muted, on: Paper.paper, style: style) >= ContrastTests.largeTextFloor
    )
  }

  @Test(arguments: styles)
  func theRedButtonLabelReads(style: UIUserInterfaceStyle) {
    #expect(Contrast.ratio(Paper.onRed, on: Paper.red, style: style) >= ContrastTests.floor)
  }
}
