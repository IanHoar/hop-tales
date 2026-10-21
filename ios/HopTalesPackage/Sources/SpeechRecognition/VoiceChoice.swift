import Foundation

struct VoiceCandidate: Hashable, Sendable {
  let id: String
  let name: String
  let language: String
  let quality: Int
  let isNovelty: Bool

  init(id: String, name: String, language: String, quality: Int, isNovelty: Bool = false) {
    self.id = id
    self.name = name
    self.language = language
    self.quality = quality
    self.isNovelty = isNovelty
  }
}

enum VoiceChoice {
  static let preferredName = "Samantha"
  static let defaultQuality = 1

  static func best(_ candidates: [VoiceCandidate], accent: String) -> VoiceCandidate? {
    let english = candidates.filter {
      normalized($0.language).hasPrefix("en") && !$0.isNovelty
    }
    let local = english.filter { normalized($0.language) == normalized(accent) }
    return pick(local) ?? pick(english)
  }

  private static func pick(_ voices: [VoiceCandidate]) -> VoiceCandidate? {
    let named = voices.first { $0.name == preferredName && $0.quality > defaultQuality }
    let finest = voices.sorted { ($1.quality, $0.name) < ($0.quality, $1.name) }.first
    let enhanced = finest.flatMap { $0.quality > defaultQuality ? $0 : nil }
    return named ?? enhanced ?? voices.first { $0.name == preferredName } ?? finest
  }

  private static func normalized(_ tag: String) -> String {
    tag.replacingOccurrences(of: "_", with: "-").lowercased()
  }
}
