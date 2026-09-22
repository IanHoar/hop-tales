import Foundation

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
