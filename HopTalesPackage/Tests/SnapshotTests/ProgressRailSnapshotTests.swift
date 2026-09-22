import SnapshotTesting
import SwiftUI
import Testing

@testable import Reading

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff))
struct ProgressRailSnapshotTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func firstSentence(scheme: ColorScheme) {
    expectSnapshot(of: ProgressRailPreview(.firstSentence), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func midStory(scheme: ColorScheme) {
    expectSnapshot(of: ProgressRailPreview(.midStory), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func sentenceWithANewWord(scheme: ColorScheme) {
    expectSnapshot(of: ProgressRailPreview(.sentenceWithANewWord), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func lastSentence(scheme: ColorScheme) {
    expectSnapshot(of: ProgressRailPreview(.lastSentence), scheme: scheme)
  }
}
