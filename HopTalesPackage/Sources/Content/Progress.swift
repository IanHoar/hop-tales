import Foundation

public struct Progress: Codable, Hashable, Sendable {
  public var completedSentences: [String: Int]
  public var stars: Int
  public var wordsRead: [String: Int]
  public var journey: Journey
  public var baskets: [Friend: Basket]

  public init(
    stars: Int = 0,
    completedSentences: [String: Int] = [:],
    wordsRead: [String: Int] = [:],
    journey: Journey = Journey(),
    baskets: [Friend: Basket] = [:]
  ) {
    self.completedSentences = completedSentences
    self.stars = stars
    self.wordsRead = wordsRead
    self.journey = journey
    self.baskets = baskets
  }

  enum CodingKeys: String, CodingKey {
    case completedSentences
    case stars
    case wordsRead
    case journey
    case baskets
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    completedSentences = try container.decode([String: Int].self, forKey: .completedSentences)
    stars = try container.decode(Int.self, forKey: .stars)
    wordsRead = try container.decode([String: Int].self, forKey: .wordsRead)
    journey = try container.decodeIfPresent(Journey.self, forKey: .journey) ?? Journey()
    baskets = try container.decodeIfPresent([Friend: Basket].self, forKey: .baskets) ?? [:]
  }
}
