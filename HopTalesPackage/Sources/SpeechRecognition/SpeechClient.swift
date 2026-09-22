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

  public var listen: @Sendable (_ contextualStrings: [String]) async throws -> AsyncStream<Event>
  public var requestAuthorization: @Sendable () async -> Authorization
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
