import DesignSystem
import SnapshotTesting
import SwiftUI
import Testing

@testable import Onboarding

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff))
struct OnboardingSnapshotTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func askingForAName(scheme: ColorScheme) {
    expectSnapshot(of: OnboardingPreview(.name), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func askingForTheMicrophone(scheme: ColorScheme) {
    expectSnapshot(of: OnboardingPreview(.listening), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func pickingAStartingFriend(scheme: ColorScheme) {
    expectSnapshot(of: OnboardingPreview(.friend), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func pickingAnAccent(scheme: ColorScheme) {
    expectSnapshot(of: OnboardingPreview(.accent), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func theSheetIsCentredOnAnIPad(scheme: ColorScheme) {
    expectSnapshot(of: OnboardingPreview(.friend, size: Metrics.pad.reference), scheme: scheme)
  }
}
