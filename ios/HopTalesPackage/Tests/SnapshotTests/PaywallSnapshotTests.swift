import SnapshotTesting
import SwiftUI
import Testing

@testable import GrownUps

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff))
struct PaywallSnapshotTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func thePaywallLeadsWithYearly(scheme: ColorScheme) {
    expectSnapshot(of: PaywallPreview(), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func theOnboardingPaywallOffersLevelOneFree(scheme: ColorScheme) {
    expectSnapshot(of: PaywallPreview(isOnboarding: true), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func theStoreIsNotAnswering(scheme: ColorScheme) {
    expectSnapshot(of: PaywallPreview(offers: .unavailable), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func aPurchaseIsWaitingForTheStore(scheme: ColorScheme) {
    expectSnapshot(of: PaywallPreview(isPending: true), scheme: scheme)
  }
}
