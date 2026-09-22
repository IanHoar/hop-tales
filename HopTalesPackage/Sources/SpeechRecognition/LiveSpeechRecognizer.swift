import AVFoundation
import Foundation
import Speech

actor LiveSpeechRecognizer {
  enum Failure: Error {
    case unsupportedDevice
    case notAuthorized
    case audioSessionUnavailable
  }

  static let locale = Locale(identifier: "en-CA")
  static let silenceTick = Duration.milliseconds(500)

  private let recognizer: SFSpeechRecognizer?
  private let engine = AVAudioEngine()
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?

  init() {
    recognizer = SFSpeechRecognizer(locale: Self.locale)
  }

  static func authorization() async -> SpeechClient.Authorization {
    guard let recognizer = SFSpeechRecognizer(locale: locale),
      recognizer.supportsOnDeviceRecognition
    else { return .unsupported }

    let speech = await withCheckedContinuation { continuation in
      SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
    }
    guard speech == .authorized else { return .denied }

    let microphone = await AVAudioApplication.requestRecordPermission()
    return microphone ? .authorized : .denied
  }

  func listen(contextualStrings: [String]) throws -> AsyncStream<SpeechClient.Event> {
    guard let recognizer, recognizer.supportsOnDeviceRecognition else {
      throw Failure.unsupportedDevice
    }
    guard recognizer.isAvailable else { throw Failure.notAuthorized }

    try configureSession()

    let request = SFSpeechAudioBufferRecognitionRequest()
    request.requiresOnDeviceRecognition = true
    request.shouldReportPartialResults = true
    request.taskHint = .dictation
    request.contextualStrings = contextualStrings
    self.request = request

    let input = engine.inputNode
    input.removeTap(onBus: 0)
    let format = input.outputFormat(forBus: 0)
    input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
      request.append(buffer)
    }
    engine.prepare()
    try engine.start()

    return AsyncStream { continuation in
      let heartbeat = Task { [weak self] in
        var lastChange = ContinuousClock.now
        var lastTranscript = ""
        while !Task.isCancelled {
          try? await Task.sleep(for: Self.silenceTick)
          guard let transcript = await self?.latestTranscript else { continue }
          if transcript != lastTranscript {
            lastTranscript = transcript
            lastChange = .now
          }
          let quiet = ContinuousClock.now - lastChange
          continuation.yield(.silence(TimeInterval(quiet.components.seconds)))
        }
      }

      task = recognizer.recognitionTask(with: request) { result, error in
        if let result {
          let tokens = WordMatcher.normalize(result.bestTranscription.formattedString)
          Task { await self.remember(result.bestTranscription.formattedString) }
          continuation.yield(result.isFinal ? .final(tokens) : .partial(tokens))
          if result.isFinal { continuation.finish() }
        }
        if error != nil { continuation.finish() }
      }

      continuation.onTermination = { _ in
        heartbeat.cancel()
        Task { await self.stop() }
      }
    }
  }

  private var latestTranscript = ""

  private func remember(_ transcript: String) {
    latestTranscript = transcript
  }

  func stop() {
    task?.cancel()
    task = nil
    request?.endAudio()
    request = nil
    if engine.isRunning {
      engine.stop()
      engine.inputNode.removeTap(onBus: 0)
    }
    try? AVAudioSession.sharedInstance().setActive(
      false,
      options: .notifyOthersOnDeactivation
    )
  }

  private func configureSession() throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(
      .record,
      mode: .measurement,
      options: [.duckOthers, .allowBluetooth]
    )
    try session.setActive(true, options: .notifyOthersOnDeactivation)
  }
}
