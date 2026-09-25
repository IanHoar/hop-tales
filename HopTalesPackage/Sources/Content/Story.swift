import Foundation

public enum Sky: String, Codable, Hashable, Sendable, CaseIterable {
  case day
  case golden
  case dusk
  case night
}

public enum Weather: String, Codable, Hashable, Sendable, CaseIterable {
  case clear
  case clouds
  case storm
  case rain
}

public struct Mood: Codable, Hashable, Sendable {
  public var sky: Sky
  public var weather: Weather

  public init(sky: Sky = .day, weather: Weather = .clear) {
    self.sky = sky
    self.weather = weather
  }
}

public struct Word: Codable, Hashable, Sendable {
  public var homophones: [String]
  public var text: String
  public var big: Bool

  public init(text: String, homophones: [String] = [], big: Bool = false) {
    self.homophones = homophones
    self.text = text
    self.big = big
  }
}

public struct Sentence: Codable, Hashable, Sendable {
  public var newWord: String?
  public var words: [Word]
  public var sky: Sky?
  public var weather: Weather?

  public init(words: [Word], newWord: String? = nil, sky: Sky? = nil, weather: Weather? = nil) {
    self.newWord = newWord
    self.words = words
    self.sky = sky
    self.weather = weather
  }
}

public struct Story: Codable, Hashable, Sendable, Identifiable {
  public static let stepPerWord: Double = 140

  public var id: String
  public var sentences: [Sentence]
  public var mood: Mood
  public var title: String
  public var level: Int
  public var stretch: Bool
  public var isBigStory: Bool

  public init(
    id: String,
    title: String,
    sentences: [Sentence],
    mood: Mood = Mood(),
    level: Int = 1,
    stretch: Bool = false,
    isBigStory: Bool = false
  ) {
    self.id = id
    self.sentences = sentences
    self.mood = mood
    self.title = title
    self.level = level
    self.stretch = stretch
    self.isBigStory = isBigStory
  }

  public var friend: Friend { Friend.at(level: level) }

  public var wordCount: Int {
    sentences.reduce(0) { $0 + $1.words.count }
  }

  public func mood(atSentence index: Int) -> Mood {
    var mood = mood
    for sentence in sentences.prefix(max(0, index) + 1) {
      if let sky = sentence.sky { mood.sky = sky }
      if let weather = sentence.weather { mood.weather = weather }
    }
    return mood
  }

  public var finalMood: Mood {
    mood(atSentence: sentences.count - 1)
  }
}
