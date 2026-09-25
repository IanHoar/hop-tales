import DesignSystem
import SnapshotTesting
import SwiftUI
import Testing

@testable import AppFeature

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff))
struct IntroSnapshotTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func theTitleStaysLightOverTheSunrise(scheme: ColorScheme) {
    expectSnapshot(
      of: IntroTitle(shown: true)
        .frame(width: Metrics.phone.reference.width, height: 320)
        .background(Color(hex: 0xC6DCEB)),
      scheme: scheme
    )
  }
}
