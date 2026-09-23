import ComposableArchitecture2
import Content
import Dependencies
import Foundation

public struct SpeechClient: Sendable {
  public enum Authorization: Hashable, Sendable {
    case authorized
    case denied
    case unsupported
  }

  public enum Event: Hashable, Sendable {
    case partial([String])
    case final([String])
    case silence(TimeInterval)
  }

  public var listen:
    @Sendable (_ contextualStrings: [String], _ locale: Locale) async throws -> AsyncStream<Event>
  public var requestAuthorization: @Sendable (_ locale: Locale) async -> Authorization
  public var speak: @Sendable (_ word: String, _ voiceID: String?) async -> Void

  public init(
    listen: @escaping @Sendable ([String], Locale) async throws -> AsyncStream<Event>,
    requestAuthorization: @escaping @Sendable (Locale) async -> Authorization,
    speak: @escaping @Sendable (String, String?) async -> Void
  ) {
    self.listen = listen
    self.requestAuthorization = requestAuthorization
    self.speak = speak
  }
}

extension SpeechClient: DependencyKey {
  public static let liveValue: SpeechClient = {
    #if targetEnvironment(simulator)
      // Speech recognition does not run in the simulator, and an unsupported-device card over the
      // reading screen makes the rest of the app untestable there. The simulator gets a client
      // that authorises, never hears anything, and still speaks — so tap-to-hear works — and
      // ReadingScreen offers a debug control to stand in for a recognised word.
      return SpeechClient(
        listen: { _, _ in AsyncStream { $0.finish() } },
        requestAuthorization: { _ in .authorized },
        speak: { word, voice in await Speaker.shared.speak(word, voiceID: voice) }
      )
    #else
      let recognizer = LiveSpeechRecognizer()
      return SpeechClient(
        listen: { contextualStrings, locale in
          try await recognizer.listen(contextualStrings: contextualStrings, locale: locale)
        },
        requestAuthorization: { locale in await LiveSpeechRecognizer.authorization(for: locale) },
        speak: { word, voice in await Speaker.shared.speak(word, voiceID: voice) }
      )
    #endif
  }()

  public static let testValue = SpeechClient(
    listen: { _, _ in AsyncStream { $0.finish() } },
    requestAuthorization: { _ in .authorized },
    speak: { _, _ in }
  )
}

extension DependencyValues {
  public var speechClient: SpeechClient {
    get { self[SpeechClient.self] }
    set { self[SpeechClient.self] = newValue }
  }
}
