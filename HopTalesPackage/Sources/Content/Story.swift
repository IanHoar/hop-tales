import Foundation

public enum StageTheme: String, Codable, Hashable, Sendable, CaseIterable {
  case meadow
  case castle
  case dragon
}

public struct Word: Codable, Hashable, Sendable {
  public var homophones: [String]
  public var text: String

  public init(text: String, homophones: [String] = []) {
    self.homophones = homophones
    self.text = text
  }
}

public struct Sentence: Codable, Hashable, Sendable {
  public var newWord: String?
  public var words: [Word]

  public init(words: [Word], newWord: String? = nil) {
    self.newWord = newWord
    self.words = words
  }
}

public struct Story: Codable, Hashable, Sendable, Identifiable {
  public var id: String
  public var sentences: [Sentence]
  public var stage: StageTheme
  public var title: String

  public init(id: String, title: String, sentences: [Sentence], stage: StageTheme) {
    self.id = id
    self.sentences = sentences
    self.stage = stage
    self.title = title
  }

  public var wordCount: Int {
    sentences.reduce(0) { $0 + $1.words.count }
  }

  public var wordStep: Double {
    guard wordCount > 0 else { return 0 }
    return 1950 / Double(wordCount)
  }
}
