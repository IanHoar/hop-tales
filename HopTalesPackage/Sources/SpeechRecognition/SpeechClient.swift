import ComposableArchitecture2
import Content
import Dependencies
import Foundation

/// The microphone side of the reading loop (`HANDOFF.md` §5).
///
/// On-device recognition only: nothing is recorded, stored, or sent anywhere. One
/// `AVAudioEngine` tap and one recognition task per *sentence* — torn down and restarted between
/// sentences to keep transcripts short.
///
/// - Note: Speech recognition does not run in the simulator. Test the reading loop on a device.
public struct SpeechClient: Sendable {
  public enum Authorization: Hashable, Sendable {
    case authorized
    case denied
    /// The device cannot do on-device recognition — show the unsupported-device sheet.
    case unsupported
  }

  public enum Event: Hashable, Sendable {
    /// A partial result. Tokens are already normalised by `WordMatcher.normalize`.
    case partial([String])
    case final([String])
    /// No change in the transcript for this long — after ~6s the app offers help.
    case silence(TimeInterval)
  }

  /// Starts a recognition session for one sentence. `contextualStrings` biases the model toward
  /// the story's vocabulary.
  public var listen: @Sendable (_ contextualStrings: [String]) async throws -> AsyncStream<Event>
  /// Mic + speech permission, requested together on first story start — never on launch.
  public var requestAuthorization: @Sendable () async -> Authorization
  /// Speaks a word aloud with `AVSpeechSynthesizer`, pausing recognition for the utterance so the
  /// app does not hear itself.
  public var speak: @Sendable (_ word: String) async -> Void

  public init(
    listen: @escaping @Sendable (_ contextualStrings: [String]) async throws -> AsyncStream<Event>,
    requestAuthorization: @escaping @Sendable () async -> Authorization,
    speak: @escaping @Sendable (_ word: String) async -> Void
  ) {
    self.listen = listen
    self.requestAuthorization = requestAuthorization
    self.speak = speak
  }
}

extension SpeechClient: DependencyKey {
  /// TODO(milestone-1): `AVAudioEngine` + `SFSpeechRecognizer(locale: "en-CA")`, on-device only,
  /// audio session `.record` / `.measurement` / `[.duckOthers, .allowBluetooth]`.
  public static let liveValue = SpeechClient(
    listen: { _ in AsyncStream { $0.finish() } },
    requestAuthorization: { .unsupported },
    speak: { _ in }
  )

  public static let testValue = SpeechClient(
    listen: { _ in AsyncStream { $0.finish() } },
    requestAuthorization: { .authorized },
    speak: { _ in }
  )
}

extension DependencyValues {
  public var speechClient: SpeechClient {
    get { self[SpeechClient.self] }
    set { self[SpeechClient.self] = newValue }
  }
}
