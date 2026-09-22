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
  static let stabilityTick = Duration.milliseconds(50)
  static let settledAfter = Duration.milliseconds(250)
  static let offerHelpAfter: TimeInterval = 6

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

    try startEngine(feeding: request)

    let (stream, continuation) = AsyncStream<SpeechClient.Event>.makeStream()
    let heartbeat = watchForSilence(yieldingTo: continuation)
    let settling = watchForSettling(yieldingTo: continuation)

    task = recognizer.recognitionTask(with: request) { @Sendable [weak self] result, error in
      if let result {
        let transcript = result.bestTranscription.formattedString
        let isFinal = result.isFinal
        continuation.yield(isFinal ? .final(WordMatcher.normalize(transcript))
          : .partial(WordMatcher.normalize(transcript)))
        Task { await self?.remember(transcript) }
        if isFinal { continuation.finish() }
      }
      if error != nil { continuation.finish() }
    }

    continuation.onTermination = { @Sendable [weak self] _ in
      heartbeat.cancel()
      settling.cancel()
      Task { await self?.stop() }
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
    try input.__installTap(onBus: 0, bufferSize: 1024, format: format, error: ()) { buffer, _ in
      request.append(buffer)
    }
    engine.prepare()
    try engine.start()
  }

  private func watchForSilence(
    yieldingTo continuation: AsyncStream<SpeechClient.Event>.Continuation
  ) -> Task<Void, Never> {
    Task { [weak self] in
      var lastChange = ContinuousClock.now
      var lastTranscript = ""
      while !Task.isCancelled {
        try? await Task.sleep(for: Self.silenceTick)
        guard let transcript = await self?.latestTranscript else { continue }
        if transcript != lastTranscript {
          lastTranscript = transcript
          lastChange = .now
        }
        let quiet = TimeInterval((ContinuousClock.now - lastChange).components.seconds)
        continuation.yield(.silence(quiet))
        if quiet >= Self.offerHelpAfter { lastChange = .now }
      }
    }
  }

  private func watchForSettling(
    yieldingTo continuation: AsyncStream<SpeechClient.Event>.Continuation
  ) -> Task<Void, Never> {
    Task { [weak self] in
      var repeated = ""
      while !Task.isCancelled {
        try? await Task.sleep(for: Self.stabilityTick)
        guard let (transcript, changed) = await self?.latest,
          !transcript.isEmpty, transcript != repeated,
          ContinuousClock.now - changed >= Self.settledAfter
        else { continue }
        repeated = transcript
        continuation.yield(.partial(WordMatcher.normalize(transcript)))
      }
    }
  }

  private var latestTranscript = ""
  private var latestChange = ContinuousClock.now

  private var latest: (String, ContinuousClock.Instant) {
    (latestTranscript, latestChange)
  }

  private func remember(_ transcript: String) {
    if transcript != latestTranscript { latestChange = .now }
    latestTranscript = transcript
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
      options: [.duckOthers, .allowBluetoothHFP]
    )
    try session.setActive(true, options: .notifyOthersOnDeactivation)
  }
}
