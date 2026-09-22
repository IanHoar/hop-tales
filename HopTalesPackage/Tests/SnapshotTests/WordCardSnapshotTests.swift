import Content
import DesignSystem
import SnapshotTesting
import SwiftUI
import Testing

@testable import Reading

/// Reference images for the reading surface, in both colour schemes.
///
/// The chrome is cream on every stage and every scheme — `docs/HANDOFF.md` §3 says chrome never
/// changes with time of day, only the world does. The light and dark pairs are therefore expected
/// to be *identical*; recording both is what catches a system colour (or a `.primary`, or a
/// material) sneaking in and repainting the card at night.
///
/// - Note: Snapshots are recorded on iPhone 18 Pro / iOS 27. Run them on that simulator, and
///   re-record when the bundled fonts land (#30) — the type here is still the system fallback.
@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff))
struct WordCardSnapshotTests {
  /// The card on its meadow background, at its own size plus room for the shadow.
  static func card(
    sentence: Sentence,
    currentIndex: Int,
    scheme: ColorScheme
  ) -> some View {
    let geometry = ReadingGeometry(size: snapshotReferenceSize)
    return ZStack {
      Color(hex: 0x8FCB6B)
      WordCard(words: sentence.words, currentIndex: currentIndex, geometry: geometry)
    }
    .frame(width: snapshotReferenceSize.width, height: geometry.cardSize.height + 64)
    .environment(\.colorScheme, scheme)
  }

  static let meadow = StoryLibrary.all[0]
  static let castle = StoryLibrary.all[1]

  @Test(arguments: [ColorScheme.light, .dark])
  func firstWordOfTheSentence(scheme: ColorScheme) {
    expectSnapshot(
      of: Self.card(sentence: Self.meadow.sentences[0], currentIndex: 0, scheme: scheme),
      as: .image(layout: .sizeThatFits),
      named: "\(scheme)"
    )
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func midSentenceWithPillsAndUpcomingWords(scheme: ColorScheme) {
    expectSnapshot(
      of: Self.card(sentence: Self.meadow.sentences[0], currentIndex: 2, scheme: scheme),
      as: .image(layout: .sizeThatFits),
      named: "\(scheme)"
    )
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func lastWordOfTheSentence(scheme: ColorScheme) {
    expectSnapshot(
      of: Self.card(sentence: Self.meadow.sentences[0], currentIndex: 5, scheme: scheme),
      as: .image(layout: .sizeThatFits),
      named: "\(scheme)"
    )
  }

  /// "The young knight rode past." — the current word shrinks so it and its neighbours fit the
  /// card, rather than the card growing.
  @Test(arguments: [ColorScheme.light, .dark])
  func longWordShrinksToFitTheCard(scheme: ColorScheme) {
    expectSnapshot(
      of: Self.card(sentence: Self.castle.sentences[2], currentIndex: 2, scheme: scheme),
      as: .image(layout: .sizeThatFits),
      named: "\(scheme)"
    )
  }
}
