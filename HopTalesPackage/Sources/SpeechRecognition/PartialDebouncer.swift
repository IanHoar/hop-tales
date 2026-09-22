import Foundation

/// Rule 5 of `HANDOFF.md` §5: a token only counts once it has appeared in two consecutive partial
/// results, or once the result is final. This kills single-frame misfires without adding latency
/// the child can feel.
public struct PartialDebouncer: Hashable, Sendable {
  private var previousTail: [String] = []

  public init() {}

  /// Feeds a recognition result in and returns the tokens that are now eligible to be matched.
  public mutating func confirm(tokens: [String], isFinal: Bool) -> [String] {
    let tail = Array(tokens.suffix(3))
    defer { previousTail = tail }
    guard !isFinal else { return tail }
    let seenBefore = Set(previousTail)
    return tail.filter { seenBefore.contains($0) }
  }

  /// Called between sentences, when the recognition task is torn down and restarted.
  public mutating func reset() {
    previousTail = []
  }
}
