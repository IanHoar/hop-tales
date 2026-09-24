import AVFoundation
import Dependencies

public struct SoundClient: Sendable {
  public var sentenceCompleted: @Sendable () async -> Void

  public init(sentenceCompleted: @escaping @Sendable () async -> Void) {
    self.sentenceCompleted = sentenceCompleted
  }
}

extension SoundClient: DependencyKey {
  public static let liveValue = SoundClient(sentenceCompleted: { await ChordPlayer.shared.play() })
  public static let testValue = SoundClient(sentenceCompleted: {})
}

enum Chord {
  static let notes: [Double] = [523.25, 659.25, 783.99, 1046.5]
  static let stagger: TimeInterval = 0.045
  static let decay: TimeInterval = 0.38
  static let length: TimeInterval = 1.1
  static let level: Float = 0.2
  static let release: TimeInterval = 0.2
  static let sampleRate: Double = 44_100

  static func sample(at time: TimeInterval) -> Float {
    var value = 0.0
    for (index, frequency) in notes.enumerated() {
      let local = time - Double(index) * stagger
      guard local >= 0 else { continue }
      let attack = min(local / 0.004, 1)
      let fundamental = sin(2 * .pi * frequency * local)
      let overtone = 0.25 * sin(2 * .pi * frequency * 3.93 * local) * exp(-local / 0.06)
      value += attack * exp(-local / decay) * (fundamental + overtone)
    }
    let fade = min(max((length - time) / release, 0), 1)
    return Float(value * fade) * level
  }

  static func buffer() -> AVAudioPCMBuffer? {
    guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
      return nil
    }
    let frames = AVAudioFrameCount(length * sampleRate)
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
      let samples = buffer.floatChannelData?[0]
    else { return nil }
    buffer.frameLength = frames
    for frame in 0..<Int(frames) {
      samples[frame] = sample(at: Double(frame) / sampleRate)
    }
    return buffer
  }
}

@MainActor
final class ChordPlayer {
  static let shared = ChordPlayer()

  private let engine = AVAudioEngine()
  private let player = AVAudioPlayerNode()
  private let chord = Chord.buffer()

  private init() {}

  func play() async {
    guard let chord else { return }
    do {
      guard try await Self.activateSession() else { return }
      if player.engine == nil {
        engine.attach(player)
        try engine.connectNode(player, to: engine.mainMixerNode, format: chord.format)
      }
      try engine.start()
      try player.playAudio()
    } catch {
      return
    }
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      let finished: @Sendable (AVAudioPlayerNodeCompletionCallbackType) -> Void = { _ in
        continuation.resume()
      }
      player.scheduleBuffer(
        chord,
        at: nil,
        options: [],
        completionCallbackType: .dataPlayedBack,
        completionHandler: finished
      )
    }
    player.stop()
    engine.stop()
  }

  @concurrent
  nonisolated private static func activateSession() async throws -> Bool {
    let session = AVAudioSession.sharedInstance()
    if session.category != .ambient {
      try session.setCategory(.ambient)
    }
    return try await session.activate(options: [])
  }
}
