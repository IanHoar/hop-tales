import Content
import Foundation

public enum WordMatcher {
  public enum Strictness: String, Codable, Hashable, Sendable, CaseIterable {
    case gentle
    case standard
  }

  public enum Target: Hashable, Sendable {
    case current
    case next
  }

  public struct Match: Hashable, Sendable {
    public var target: Target
    public var token: String

    public init(target: Target, token: String) {
      self.target = target
      self.token = token
    }
  }

  static let soundsAlike: [String: Set<String>] = [
    "the": ["a", "uh", "duh", "da", "de", "dee", "thee", "thuh", "they", "then"],
    "a": ["ay", "ah", "eh", "uh", "ea", "ear", "eara", "era", "hey", "oh", "o"],
    "bee": ["be", "bea"],
    "on": ["oh", "awn", "ahn", "own"]
  ]

  static let letterNames: [String: Set<String>] = [
    "a": ["a"], "b": ["bee", "be"], "c": ["see", "sea"], "d": ["dee"], "g": ["gee"],
    "i": ["i", "eye"], "j": ["jay"], "k": ["kay"], "o": ["oh", "owe"], "p": ["pea", "pee"],
    "q": ["queue"], "r": ["are"], "t": ["tea", "tee"], "u": ["you"], "y": ["why"]
  ]

  static let vowels = Set("aeiouy")
  static let stops: Set<Character> = ["b", "d", "g", "k", "p", "t"]

  static let voicing: [Character: Character] = [
    "t": "d", "d": "t", "p": "b", "b": "p", "k": "g", "g": "k", "s": "z", "z": "s"
  ]

  static let spelledNumbers: [String: String] = [
    "0": "zero", "1": "one", "2": "two", "3": "three", "4": "four", "5": "five",
    "6": "six", "7": "seven", "8": "eight", "9": "nine", "10": "ten"
  ]

  public static func normalize(_ transcript: String) -> [String] {
    transcript
      .lowercased()
      .replacingOccurrences(of: "\u{2019}", with: "")
      .replacingOccurrences(of: "'", with: "")
      .components(separatedBy: .whitespacesAndNewlines)
      .map { $0.trimmingCharacters(in: CharacterSet.alphanumerics.inverted) }
      .filter { !$0.isEmpty }
      .map { spelledNumbers[$0] ?? $0 }
  }

  public static func match(
    tokens: [String],
    current: Word,
    next: Word?,
    strictness: Strictness = .gentle
  ) -> Match? {
    let tail = tokens.suffix(3)
    guard !tail.isEmpty else { return nil }

    if let next {
      for token in tail.reversed() {
        guard accepts(token: token, target: next, strictness: strictness),
              !accepts(token: token, target: current, strictness: strictness) else { continue }
        return Match(target: .next, token: token)
      }
    }
    for token in tail.reversed() {
      guard accepts(token: token, target: current, strictness: strictness) else { continue }
      return Match(target: .current, token: token)
    }
    return nil
  }

  static func collapsed(_ token: String) -> String {
    var result = ""
    for character in token where character != result.last { result.append(character) }
    return result
  }

  static func accepts(token: String, target: Word, strictness: Strictness) -> Bool {
    let text = normalize(target.text).joined()
    guard !token.isEmpty, !text.isEmpty else { return false }
    let token = token.count > 1 && collapsed(token).count == 1 ? collapsed(token) : token
    if letterNames[token]?.contains(text) == true { return true }

    if token == text { return true }
    if text.count >= 4, oneLetterAddedOrDropped(token, text) { return true }
    guard strictness == .gentle else { return false }

    let squeezed = collapsed(token)
    if target.homophones.contains(where: { $0.lowercased() == token }) { return true }
    if soundsAlike[text]?.contains(token) == true { return true }
    if soundsAlike[text]?.contains(collapsed(token)) == true { return true }
    return soundsLikeShortWord(token, text) || soundsLikeShortWord(squeezed, text)
  }

  static func soundsLikeShortWord(_ token: String, _ text: String) -> Bool {
    let target = Array(text), heard = Array(token)
    let opens = target.first == "y" || target.first.map { !vowels.contains($0) } == true
    guard
      target.count == 3, opens, vowels.contains(target[1]),
      !vowels.contains(target[2]), (3...4).contains(heard.count),
      let first = heard.first, let last = heard.last, first == target[0],
      last == target[2] || last == voicing[target[2]]
        || (stops.contains(last) && stops.contains(target[2]))
    else { return false }
    return heard.dropFirst().dropLast().allSatisfy(vowels.contains)
  }

  static func oneLetterAddedOrDropped(_ lhs: String, _ rhs: String) -> Bool {
    let (short, long) = lhs.count < rhs.count ? (Array(lhs), Array(rhs)) : (Array(rhs), Array(lhs))
    guard long.count == short.count + 1 else { return false }
    return long.indices.contains { index in
      var trimmed = long
      trimmed.remove(at: index)
      return trimmed == short
    }
  }
}
