import Foundation

public struct PartialDebouncer: Hashable, Sendable {
  private var previousTail: [String] = []
  public init() {}

  public mutating func confirm(tokens: [String], isFinal: Bool) -> [String] {
    let tail = Array(tokens.suffix(3))
    defer { previousTail = tail }
    guard !isFinal else { return tail }
    let seenBefore = Set(previousTail)
    return tail.filter { seenBefore.contains($0) }
  }

  public mutating func reset() {
    previousTail = []
  }
}
