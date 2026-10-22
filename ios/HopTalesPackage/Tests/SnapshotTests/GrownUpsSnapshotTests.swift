import Content
import Foundation
import SnapshotTesting
import SwiftUI
import Testing

@testable import GrownUps
@testable import Reading

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff))
struct GrownUpsSnapshotTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func everySetting(scheme: ColorScheme) {
    expectSnapshot(of: SettingsPreview(height: 2560), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func everySettingOnAnIPad(scheme: ColorScheme) {
    expectSnapshot(of: SettingsPreview(width: 700, height: 2560), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func plusWhenFree(scheme: ColorScheme) {
    expectSnapshot(of: PlusSectionPreview(foundNothingToRestore: true), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func plusRenews(scheme: ColorScheme) {
    let status = PlusStatus(.renews(PlusSectionPreview.renewal), refundableTransactionID: 1)
    expectSnapshot(of: PlusSectionPreview(plus: status), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func plusEnds(scheme: ColorScheme) {
    let status = PlusStatus(.ends(PlusSectionPreview.renewal), refundableTransactionID: 1)
    expectSnapshot(of: PlusSectionPreview(plus: status), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func plusSharedByTheFamily(scheme: ColorScheme) {
    expectSnapshot(of: PlusSectionPreview(plus: PlusStatus(.familyShared)), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func plusWithAPaymentProblem(scheme: ColorScheme) {
    let status = PlusStatus(.paymentProblem, refundableTransactionID: 1)
    expectSnapshot(of: PlusSectionPreview(plus: status), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func stoppingAStoryAsksFirst(scheme: ColorScheme) {
    expectSnapshot(of: StopReadingPreview(), scheme: scheme)
  }
}
