import Foundation

/// Persisted in Application Support as JSON, one file (`HANDOFF.md` §8).
///
/// Stars: 1 per word, +5 for a sentence read with no help, +20 for a finished story. They unlock
/// nothing in v1 — they are the counter in the top-right chip.
public struct Progress: Codable, Hashable, Sendable {
  public var completedSentences: [String: Int]
  public var stars: Int
  public var wordsRead: [String: Int]

  public init(
    stars: Int = 0,
    completedSentences: [String: Int] = [:],
    wordsRead: [String: Int] = [:]
  ) {
    self.completedSentences = completedSentences
    self.stars = stars
    self.wordsRead = wordsRead
  }
}
