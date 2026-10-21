import AVFoundation
import Foundation

@MainActor
final class Speaker: NSObject {
  static let shared = Speaker()

  static let rate: Float = 0.42

  private let synthesizer = AVSpeechSynthesizer()
  private var finished: CheckedContinuation<Void, Never>?

  override private init() {
    super.init()
    synthesizer.delegate = self
  }

  func speak(_ word: String, voiceID: String? = nil, locale: Locale) async {
    synthesizer.stopSpeaking(at: .immediate)
    resume()

    let utterance = AVSpeechUtterance(string: word)
    utterance.rate = Self.rate
    utterance.voice = voiceID.flatMap(AVSpeechSynthesisVoice.init(identifier:))
      ?? Self.voice(for: locale)

    await withCheckedContinuation { continuation in
      finished = continuation
      synthesizer.speak(utterance)
    }
  }

  static func voice(for locale: Locale) -> AVSpeechSynthesisVoice? {
    let candidates = AVSpeechSynthesisVoice.speechVoices().map {
      VoiceCandidate(
        id: $0.identifier,
        name: $0.name,
        language: $0.language,
        quality: $0.quality.rawValue,
        isNovelty: $0.voiceTraits.contains(.isNoveltyVoice)
      )
    }
    let accent = locale.identifier(.bcp47)
    return VoiceChoice.best(candidates, accent: accent)
      .flatMap { AVSpeechSynthesisVoice(identifier: $0.id) }
      ?? AVSpeechSynthesisVoice(language: accent)
  }

  nonisolated static func voices() -> [Voice] {
    let english = AVSpeechSynthesisVoice.speechVoices().filter {
      $0.language.hasPrefix("en") && !$0.voiceTraits.contains(.isNoveltyVoice)
    }
    let best = Dictionary(grouping: english, by: \.name).compactMap { _, voices in
      voices.max { $0.quality.rawValue < $1.quality.rawValue }
    }
    return best
      .map { Voice(id: $0.identifier, name: $0.name, language: $0.language) }
      .sorted { ($0.name, $0.language) < ($1.name, $1.language) }
  }

  private func resume() {
    finished?.resume()
    finished = nil
  }
}

extension Speaker: AVSpeechSynthesizerDelegate {
  nonisolated func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer,
    didFinish utterance: AVSpeechUtterance
  ) {
    Task { @MainActor in resume() }
  }

  nonisolated func speechSynthesizer(
    _ synthesizer: AVSpeechSynthesizer,
    didCancel utterance: AVSpeechUtterance
  ) {
    Task { @MainActor in resume() }
  }
}
