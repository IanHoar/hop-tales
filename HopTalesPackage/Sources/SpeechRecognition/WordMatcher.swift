import Content
import Foundation

/// Decides whether what the recogniser heard counts as the child reading the word on screen
/// (`HANDOFF.md` §5).
///
/// A five-year-old's pronunciation is not a dictation test: matching is forgiving by default and
/// never produces a failure state. This type is a pure function so the tolerance rules can be
/// tuned against `WordMatcherTests` without a microphone.
public enum WordMatcher {
  /// A parent setting. `gentle` is the default.
  public enum Strictness: String, Codable, Hashable, Sendable, CaseIterable {
    /// Exact match, Levenshtein ≤ 1, shared-prefix-and-length, or a homophone.
    case gentle
    /// Exact match or Levenshtein ≤ 1 only.
    case standard
  }

  public enum Target: Hashable, Sendable {
    /// The big word in the middle of the card.
    case current
    /// The child read ahead — the current word is marked read too.
    case next
  }

  public struct Match: Hashable, Sendable {
    public var target: Target
    /// What the recogniser actually heard, kept for the "Heard it — “sat”" pill.
    public var token: String

    public init(target: Target, token: String) {
      self.target = target
      self.token = token
    }
  }

  /// Lowercase, strip punctuation, split on whitespace.
  public static func normalize(_ transcript: String) -> [String] {
    transcript
      .lowercased()
      .components(separatedBy: .whitespacesAndNewlines)
      .map { $0.trimmingCharacters(in: CharacterSet.alphanumerics.inverted) }
      .filter { !$0.isEmpty }
  }

  /// Matches the tail of a transcript against the current word, and against the next word for
  /// children who read ahead.
  ///
  /// - Parameters:
  ///   - tokens: Normalised transcript tokens. Only the last three are considered.
  ///   - current: The word the ball is sitting on.
  ///   - next: The word after it, if the sentence has one.
  ///   - strictness: The parent's tolerance setting.
  public static func match(
    tokens: [String],
    current: Word,
    next: Word?,
    strictness: Strictness = .gentle
  ) -> Match? {
    let tail = tokens.suffix(3)
    guard !tail.isEmpty else { return nil }

    // Read-ahead wins: if the child has already said the next word, the current one is read too.
    if let next {
      for token in tail.reversed() {
        guard accepts(token: token, target: next, strictness: strictness) else { continue }
        return Match(target: .next, token: token)
      }
    }
    for token in tail.reversed() {
      guard accepts(token: token, target: current, strictness: strictness) else { continue }
      return Match(target: .current, token: token)
    }
    return nil
  }

  static func accepts(token: String, target: Word, strictness: Strictness) -> Bool {
    let text = target.text.lowercased()
    guard !token.isEmpty, !text.isEmpty else { return false }

    if token == text { return true }
    if text.count >= 4, levenshtein(token, text) <= 1 { return true }
    guard strictness == .gentle else { return false }

    // Early readers drop and garble final consonants.
    if token.count == text.count, token.prefix(2) == text.prefix(2) { return true }
    if target.homophones.contains(where: { $0.lowercased() == token }) { return true }
    return false
  }

  static func levenshtein(_ lhs: String, _ rhs: String) -> Int {
    let lhs = Array(lhs), rhs = Array(rhs)
    guard !lhs.isEmpty else { return rhs.count }
    guard !rhs.isEmpty else { return lhs.count }

    var previous = Array(0...rhs.count)
    var current = [Int](repeating: 0, count: rhs.count + 1)
    for i in 1...lhs.count {
      current[0] = i
      for j in 1...rhs.count {
        let substitution = previous[j - 1] + (lhs[i - 1] == rhs[j - 1] ? 0 : 1)
        current[j] = min(previous[j] + 1, current[j - 1] + 1, substitution)
      }
      swap(&previous, &current)
    }
    return previous[rhs.count]
  }
}
