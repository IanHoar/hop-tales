import SnapshotTesting
import SwiftUI
import Testing

@testable import Reading

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff))
struct WordCardSnapshotTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func firstWordOfTheSentence(scheme: ColorScheme) {
    expectSnapshot(of: WordCardPreview(.firstWord), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func midSentenceWithPillsAndUpcomingWords(scheme: ColorScheme) {
    expectSnapshot(of: WordCardPreview(.midSentence), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func lastWordOfTheSentence(scheme: ColorScheme) {
    expectSnapshot(of: WordCardPreview(.lastWord), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func longWordShrinksToFitTheCard(scheme: ColorScheme) {
    expectSnapshot(of: WordCardPreview(.longWord), scheme: scheme)
  }
}
