import AVFoundation
import Foundation
import Speech
import Synchronization

actor LiveSpeechRecognizer {
  enum Failure: Error {
    case unsupportedDevice
    case notAuthorized
    case audioSessionUnavailable
  }

  static let silenceTick = Duration.milliseconds(500)
  static let stabilityTick = Duration.milliseconds(50)
  static let settledAfter = Duration.milliseconds(250)
  static let offerHelpAfter: TimeInterval = 6

  private var recognizer: SFSpeechRecognizer?
  private let engine = AVAudioEngine()
  private let meter = NoiseMeter()
  private let heard = HeardTranscript()
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private var release: Task<Void, Never>?

  static let releaseSessionAfter = Duration.seconds(3)

  static var isAuthorized: Bool {
    SFSpeechRecognizer.authorizationStatus() == .authorized
      && AVAudioApplication.shared.recordPermission == .granted
  }

  static func authorization(for locale: Locale) async -> SpeechClient.Authorization {
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

  func listen(
    contextualStrings: [String],
    locale: Locale
  ) throws -> AsyncStream<SpeechClient.Event> {
    if recognizer?.locale.identifier != locale.identifier {
      recognizer = SFSpeechRecognizer(locale: locale)
    }
    guard let recognizer, recognizer.supportsOnDeviceRecognition else {
      throw Failure.unsupportedDevice
    }
    guard recognizer.isAvailable else { throw Failure.notAuthorized }

    release?.cancel()
    release = nil
    try ReadingAudio.activate()

    let request = SFSpeechAudioBufferRecognitionRequest()
    request.requiresOnDeviceRecognition = true
    request.shouldReportPartialResults = true
    request.taskHint = .dictation
    request.contextualStrings = contextualStrings
    self.request = request

    try startEngine(feeding: request)

    let (stream, continuation) = AsyncStream<SpeechClient.Event>.makeStream()
    let heartbeat = watchForSilence(yieldingTo: continuation)
    let settling = watchForSettling(yieldingTo: continuation)
    let disruptions = Self.watchForDisruptions(ending: continuation)

    let heard = heard
    task = recognizer.recognitionTask(with: request) { @Sendable result, error in
      if let result {
        let transcript = result.bestTranscription.formattedString
        let isFinal = result.isFinal
        continuation.yield(isFinal ? .final(WordMatcher.normalize(transcript))
          : .partial(WordMatcher.normalize(transcript)))
        heard.remember(transcript)
        if isFinal { continuation.finish() }
      }
      if error != nil { continuation.finish() }
    }

    let session = ObjectIdentifier(request)
    continuation.onTermination = { @Sendable [weak self] _ in
      heartbeat.cancel()
      settling.cancel()
      disruptions.forEach { $0.cancel() }
      Task { await self?.stop(session: session) }
    }

    return stream
  }

  private func startEngine(feeding request: SFSpeechAudioBufferRecognitionRequest) throws {
    let input = engine.inputNode
    input.removeTap(onBus: 0)
    let format = input.outputFormat(forBus: 0)
    guard format.sampleRate > 0, format.channelCount > 0 else {
      throw Failure.audioSessionUnavailable
    }
    let meter = meter
    let feed: AVAudioNodeTapBlock = { buffer, _ in
      request.append(buffer)
      meter.feed(buffer)
    }
    if #available(iOS 27, *) {
      try input.__installTap(onBus: 0, bufferSize: 1024, format: format, error: (), block: feed)
    } else {
      input.installTap(onBus: 0, bufferSize: 1024, format: format, block: feed)
    }
    engine.prepare()
    try engine.start()
  }

  private func watchForSilence(
    yieldingTo continuation: AsyncStream<SpeechClient.Event>.Continuation
  ) -> Task<Void, Never> {
    let meter = meter
    let heard = heard
    return Task {
      var lastChange = ContinuousClock.now
      var lastTranscript = ""
      while !Task.isCancelled {
        try? await Task.sleep(for: Self.silenceTick)
        let transcript = heard.latest.transcript
        if transcript != lastTranscript {
          lastTranscript = transcript
          lastChange = .now
        }
        let quiet = TimeInterval((ContinuousClock.now - lastChange).components.seconds)
        continuation.yield(.silence(quiet))
        continuation.yield(.level(meter.floor))
        if quiet >= Self.offerHelpAfter { lastChange = .now }
      }
    }
  }

  static let disruptions: [Notification.Name] = [
    AVAudioSession.interruptionNotification,
    AVAudioSession.mediaServicesWereResetNotification,
    .AVAudioEngineConfigurationChange
  ]

  private static func watchForDisruptions(
    ending continuation: AsyncStream<SpeechClient.Event>.Continuation
  ) -> [Task<Void, Never>] {
    disruptions.map { name in
      Task {
        for await _ in NotificationCenter.default.notifications(named: name) {
          continuation.finish()
          return
        }
      }
    }
  }

  private func watchForSettling(
    yieldingTo continuation: AsyncStream<SpeechClient.Event>.Continuation
  ) -> Task<Void, Never> {
    let heard = heard
    return Task {
      var repeated = ""
      while !Task.isCancelled {
        try? await Task.sleep(for: Self.stabilityTick)
        let (transcript, changed) = heard.latest
        guard !transcript.isEmpty, transcript != repeated,
          ContinuousClock.now - changed >= Self.settledAfter
        else { continue }
        repeated = transcript
        continuation.yield(.partial(WordMatcher.normalize(transcript)))
      }
    }
  }

  func stop(session: ObjectIdentifier) {
    guard let request, ObjectIdentifier(request) == session else { return }
    stop()
  }

  func stop() {
    task?.cancel()
    task = nil
    engine.inputNode.removeTap(onBus: 0)
    if engine.isRunning {
      engine.stop()
    }
    request?.endAudio()
    request = nil
    release?.cancel()
    release = Task { [weak self] in
      try? await Task.sleep(for: Self.releaseSessionAfter)
      guard !Task.isCancelled else { return }
      await self?.releaseSession()
    }
  }

  private func releaseSession() {
    guard request == nil else { return }
    ReadingAudio.deactivate()
  }
}

final class HeardTranscript: Sendable {
  private struct Heard {
    var transcript = ""
    var changed = ContinuousClock.now
  }

  private let heard = Mutex(Heard())

  var latest: (transcript: String, changed: ContinuousClock.Instant) {
    heard.withLock { ($0.transcript, $0.changed) }
  }

  func remember(_ transcript: String) {
    heard.withLock { heard in
      if transcript != heard.transcript { heard.changed = .now }
      heard.transcript = transcript
    }
  }
}
