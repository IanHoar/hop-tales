import Foundation

public struct SoundMark: Hashable, Sendable {
  public enum Kind: Hashable, Sendable {
    case button
    case bar
    case split
  }

  public var start: Int
  public var end: Int
  public var kind: Kind

  public init(start: Int, end: Int, kind: Kind) {
    self.start = start
    self.end = end
    self.kind = kind
  }
}

extension Phonics {
  public func soundMarks(for word: String) -> [SoundMark]? {
    let word = word.lowercased()
    guard heart[word] == nil, level(of: word) != nil else { return nil }
    if word.hasSuffix("ed"), endingBases(word) != nil {
      let base = String(word.dropLast(2))
      guard let marks = marks(of: base) else { return nil }
      return marks + [SoundMark(start: base.count, end: word.count, kind: .bar)]
    }
    return marks(of: word)
  }

  private func marks(of word: String) -> [SoundMark]? {
    tokens(word)?.map { token, start in
      if token.grapheme.hasSuffix("_e") {
        return SoundMark(start: start, end: start + 3, kind: .split)
      }
      let count = token.grapheme.count
      return SoundMark(start: start, end: start + count, kind: count == 1 ? .button : .bar)
    }
  }
}
