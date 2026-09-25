import Dependencies
import Foundation
import Synchronization

public struct SpeechLogEntry: Equatable, Sendable {
  public enum Outcome: String, Sendable {
    case current
    case next
    case waiting
    case none
    case speaking
  }

  public var date: Date
  public var story: String
  public var sentence: Int
  public var word: String
  public var heard: [String]
  public var isFinal: Bool
  public var outcome: Outcome

  public init(
    date: Date = .now,
    story: String,
    sentence: Int,
    word: String,
    heard: [String],
    isFinal: Bool,
    outcome: Outcome
  ) {
    self.date = date
    self.story = story
    self.sentence = sentence
    self.word = word
    self.heard = heard
    self.isFinal = isFinal
    self.outcome = outcome
  }
}

public struct SpeechLog: Sendable {
  public static let capacity = 5000

  public var isEnabled: @Sendable () -> Bool
  public var setEnabled: @Sendable (Bool) -> Void
  public var record: @Sendable (SpeechLogEntry) -> Void
  public var entries: @Sendable () -> [SpeechLogEntry]
  public var clear: @Sendable () -> Void

  public init(
    isEnabled: @escaping @Sendable () -> Bool,
    setEnabled: @escaping @Sendable (Bool) -> Void,
    record: @escaping @Sendable (SpeechLogEntry) -> Void,
    entries: @escaping @Sendable () -> [SpeechLogEntry],
    clear: @escaping @Sendable () -> Void
  ) {
    self.isEnabled = isEnabled
    self.setEnabled = setEnabled
    self.record = record
    self.entries = entries
    self.clear = clear
  }

  public static func csv(_ entries: [SpeechLogEntry]) -> String {
    let time = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    let rows = entries.map { entry in
      [
        entry.date.formatted(time), entry.story, String(entry.sentence), entry.word,
        entry.heard.joined(separator: " "), entry.isFinal ? "final" : "partial",
        entry.outcome.rawValue
      ].joined(separator: ",")
    }
    return (["time,story,sentence,word,heard,kind,outcome"] + rows).joined(separator: "\n") + "\n"
  }
}

extension SpeechLog: DependencyKey {
  public static let key = "speech-log"

  public static func inMemory(suiteName: String? = nil) -> SpeechLog {
    let lines = Mutex<[SpeechLogEntry]>([])
    @Sendable func defaults() -> UserDefaults {
      suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }
    return SpeechLog(
      isEnabled: { defaults().bool(forKey: key) },
      setEnabled: { defaults().set($0, forKey: key) },
      record: { entry in
        guard defaults().bool(forKey: key) else { return }
        lines.withLock { lines in
          lines.append(entry)
          if lines.count > capacity { lines.removeFirst(lines.count - capacity) }
        }
      },
      entries: { lines.withLock { $0 } },
      clear: { lines.withLock { $0.removeAll() } }
    )
  }

  public static let liveValue = inMemory()

  public static let testValue = SpeechLog(
    isEnabled: { false },
    setEnabled: { _ in },
    record: { _ in },
    entries: { [] },
    clear: {}
  )
}
