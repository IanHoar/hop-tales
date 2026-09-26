import Foundation

public struct Phonics: Sendable {
  public struct Level: Decodable, Sendable {
    public var level: Int
    public var phase: String
    public var graphemes: [String]
    public var endGraphemes: [String]
    public var heartWords: [String]
  }

  struct Rules: Decodable, Sendable {
    var clusters: Int
    var splitDigraphs: Int
    var endings: Int
    var syllables: Int
    var vowelY: Int
  }

  struct Table: Decodable, Sendable {
    var names: [String]
    var rules: Rules
    var levels: [Level]
  }

  private struct Token {
    var grapheme: String
    var level: Int
    var isVowel: Bool
  }

  public static let standard = "Reading levels are based on the UFLI Foundations phonics sequence."

  public static let shared: Phonics = {
    guard
      let url = Bundle.module.url(forResource: "phonics", withExtension: "json"),
      let table = try? JSONDecoder().decode(Table.self, from: Data(contentsOf: url))
    else {
      assertionFailure("phonics.json could not be decoded")
      return Phonics(table: Table(names: [], rules: Rules(
        clusters: 2, splitDigraphs: 3, endings: 4, syllables: 4, vowelY: 6
      ), levels: []))
    }
    return Phonics(table: table)
  }()

  private static let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
  private static let silentETails: Set<String> = [
    "", "s", "d", "r", "ly", "ful", "less", "ment", "ness", "st"
  ]
  private static let endTails: Set<String> = ["", "s", "d"]
  private static let consonantUnits: Set<String> = ["qu", "dge", "ce", "ge", "ve"]

  public let levels: [Level]
  public let names: [String]
  private let rules: Rules
  private let graphemes: [String: Int]
  private let ends: [String: Int]
  private let heart: [String: Int]
  private let byLength: [String]
  private let endsByLength: [String]

  init(table: Table) {
    levels = table.levels
    names = table.names
    rules = table.rules
    var graphemes: [String: Int] = [:]
    var ends: [String: Int] = [:]
    var heart: [String: Int] = [:]
    for level in table.levels {
      for grapheme in level.graphemes { graphemes[grapheme] = level.level }
      for grapheme in level.endGraphemes { ends[grapheme] = level.level }
      for word in level.heartWords { heart[word] = level.level }
    }
    for name in table.names { heart[name.lowercased()] = 1 }
    self.graphemes = graphemes
    self.ends = ends
    self.heart = heart
    byLength = graphemes.keys.sorted { ($0.count, $0) > ($1.count, $1) }
    endsByLength = ends.keys.sorted { ($0.count, $0) > ($1.count, $1) }
  }

  public func phase(at level: Int) -> String? {
    levels.first { $0.level == level }?.phase
  }

  public func level(of word: String) -> Int? {
    let word = word.lowercased()
    return [heart[word], decoded(word)].compactMap(\.self).min()
  }

  private func decoded(_ word: String) -> Int? {
    guard let bases = endingBases(word) else { return segmented(word) }
    guard let base = bases.compactMap(level(of:)).min() else { return nil }
    return max(rules.endings, base)
  }

  private func endingBases(_ word: String) -> [String]? {
    for suffix in ["ing", "ed"] where word.hasSuffix(suffix) {
      let base = String(word.dropLast(suffix.count))
      guard base.contains(where: Self.vowels.contains), !base.hasSuffix("e") else { continue }
      var bases: [String]
      if base.hasSuffix("c") || base.hasSuffix("dg") || base.hasSuffix("v") {
        bases = [base + "e"]
      } else if split(base + "e") != nil {
        bases = [base, base + "e"]
      } else {
        bases = [base]
      }
      let letters = Array(base)
      if letters.count > 2, letters[letters.count - 1] == letters[letters.count - 2] {
        bases.append(String(base.dropLast()))
      }
      return bases
    }
    let base = String(word.dropLast(2))
    if word.hasSuffix("es"), ["ss", "x", "z", "ch", "sh"].contains(where: base.hasSuffix) {
      return [base]
    }
    return nil
  }

  private func split(_ word: String) -> Int? {
    let letters = Array(word)
    guard letters.count > 2 else { return nil }
    for index in 0..<(letters.count - 2) {
      let vowel = letters[index]
      let consonant = letters[index + 1]
      let before: Character? = index > 0 ? letters[index - 1] : nil
      let afterQu = index >= 2 && String(letters[(index - 2)..<index]) == "qu"
      let opens = before.map { !Self.vowels.contains($0) } ?? true || afterQu
      let tail = String(letters[(index + 3)...])
      if Self.vowels.contains(vowel), opens, !Self.vowels.contains(consonant),
        !"rwxy".contains(consonant), letters[index + 2] == "e", Self.silentETails.contains(tail) {
        return index
      }
    }
    return nil
  }

  private func segmented(_ word: String) -> Int? {
    let letters = Array(word)
    let split = split(word)
    var tokens: [Token] = []
    var position = 0
    while position < letters.count {
      if position == split {
        let grapheme = "\(letters[position])_e"
        tokens.append(Token(grapheme: grapheme, level: rules.splitDigraphs, isVowel: true))
        position += 1
        continue
      }
      if let split, position == split + 2 {
        position += 1
        continue
      }
      let rest = String(letters[position...])
      guard var token = endToken(rest, at: position, in: letters, split: split)
        ?? graphemeToken(rest, at: position, split: split)
      else { return nil }
      if token.grapheme == "y", position > 0, tokens.last?.isVowel == false {
        token = Token(grapheme: "y", level: rules.vowelY, isVowel: true)
      }
      tokens.append(token)
      position += token.grapheme.count
    }
    guard var level = tokens.map(\.level).max() else { return nil }
    var pairs = Array(zip(tokens, tokens.dropFirst()))
    if !pairs.isEmpty, word.hasSuffix("s"), tokens.last?.grapheme == "s" {
      pairs.removeLast()
    }
    if pairs.contains(where: { !$0.isVowel && !$1.isVowel }) {
      level = max(level, rules.clusters)
    }
    if tokens.filter(\.isVowel).count > 1 {
      level = max(level, rules.syllables)
    }
    return level
  }

  private func endToken(
    _ rest: String, at position: Int, in letters: [Character], split: Int?
  ) -> Token? {
    guard position > 0, split == nil else { return nil }
    for grapheme in endsByLength where rest.hasPrefix(grapheme) {
      let follows = grapheme != "le" || !Self.vowels.contains(letters[position - 1])
      let tail = String(rest.dropFirst(grapheme.count))
      if follows, Self.endTails.contains(tail), let level = ends[grapheme] {
        return Token(grapheme: grapheme, level: level, isVowel: grapheme == "le")
      }
    }
    return nil
  }

  private func graphemeToken(_ rest: String, at position: Int, split: Int?) -> Token? {
    for grapheme in byLength where rest.hasPrefix(grapheme) {
      let end = position + grapheme.count
      if let split, position <= split + 2, split + 2 < end { continue }
      guard let level = graphemes[grapheme] else { continue }
      let isVowel = grapheme.contains(where: Self.vowels.contains)
        && !Self.consonantUnits.contains(grapheme)
      return Token(grapheme: grapheme, level: level, isVowel: isVowel)
    }
    return nil
  }
}
