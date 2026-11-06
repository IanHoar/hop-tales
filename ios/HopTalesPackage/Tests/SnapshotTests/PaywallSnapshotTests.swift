import Content
import DependenciesTestSupport
import SnapshotTesting
import SwiftUI
import Testing

@testable import GrownUps

@MainActor
@Suite(
  .steady,
  .dependency(\.continuousClock, .immediate),
  .snapshots(record: .missing, diffTool: .ksdiff)
)
struct PaywallSnapshotTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func thePaywallLeadsWithYearly(scheme: ColorScheme) {
    expectSnapshot(of: PaywallPreview(), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func theStoreIsNotAnswering(scheme: ColorScheme) {
    expectSnapshot(of: PaywallPreview(offers: .unavailable), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func aPurchaseIsWaitingForTheStore(scheme: ColorScheme) {
    expectSnapshot(of: PaywallPreview(isPending: true), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func subscribingShowsItIsWorking(scheme: ColorScheme) {
    expectSnapshot(of: PaywallPreview(work: .subscribing), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func subscribingWelcomesTheNextFriend(scheme: ColorScheme) {
    let story = StoryLibrary.bigStory(at: 2)!
    let welcome = PlusWelcome(story: story, friend: .hare, meetsFriend: true)
    expectSnapshot(of: PaywallPreview(isSubscribed: true, welcome: welcome), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func subscribingFromSettingsWelcomesWithoutAStory(scheme: ColorScheme) {
    expectSnapshot(of: PaywallPreview(isSubscribed: true), scheme: scheme)
  }
}
