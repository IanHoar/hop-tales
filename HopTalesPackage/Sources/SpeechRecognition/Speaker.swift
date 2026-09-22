import AVFoundation
import Foundation

@MainActor
final class Speaker: NSObject {
  static let shared = Speaker()

  static let rate: Float = 0.42
  static let preferredVoice = "Samantha"

  private let synthesizer = AVSpeechSynthesizer()
  private var finished: CheckedContinuation<Void, Never>?

  override private init() {
    super.init()
    synthesizer.delegate = self
  }

  func speak(_ word: String, voiceID: String? = nil) async {
    synthesizer.stopSpeaking(at: .immediate)
    resume()

    let utterance = AVSpeechUtterance(string: word)
    utterance.rate = Self.rate
    utterance.voice = voiceID.flatMap(AVSpeechSynthesisVoice.init(identifier:)) ?? Self.voice()

    await withCheckedContinuation { continuation in
      finished = continuation
      synthesizer.speak(utterance)
    }
  }

  static func voice() -> AVSpeechSynthesisVoice? {
    let english = AVSpeechSynthesisVoice.speechVoices().filter {
      $0.language.hasPrefix("en")
    }
    let named = english.first { $0.name == preferredVoice && $0.quality != .default }
    let enhanced = english.first { $0.quality == .premium }
      ?? english.first { $0.quality == .enhanced }
    return named ?? enhanced ?? english.first { $0.name == preferredVoice }
      ?? AVSpeechSynthesisVoice(language: "en-US")
  }

  static func voices(for locale: Locale) -> [SpeechClient.Voice] {
    let english = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
    let local = english.filter { $0.language == locale.identifier }
    let pool = local.isEmpty ? english : local
    return pool
      .sorted { ($0.quality.rawValue, $1.name) > ($1.quality.rawValue, $0.name) }
      .prefix(6)
      .map { SpeechClient.Voice(id: $0.identifier, name: $0.name) }
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
