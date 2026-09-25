import Dependencies
import Foundation
import Synchronization

public struct ProgressStore: Sendable {
  public var load: @Sendable () -> Progress
  public var save: @Sendable (Progress) -> Void

  public init(
    load: @escaping @Sendable () -> Progress,
    save: @escaping @Sendable (Progress) -> Void
  ) {
    self.load = load
    self.save = save
  }
}

extension ProgressStore: DependencyKey {
  public static let fileName = "progress.json"

  static let writes = DispatchQueue(label: "com.hoptales.progress-writes", qos: .utility)

  public static func file(in directory: URL) -> ProgressStore {
    let url = directory.appending(path: fileName)
    let cached = Mutex<Progress?>(nil)
    return ProgressStore(
      load: {
        cached.withLock { cached in
          if let cached { return cached }
          let progress = (try? Data(contentsOf: url))
            .flatMap { try? JSONDecoder().decode(Progress.self, from: $0) } ?? Progress()
          cached = progress
          return progress
        }
      },
      save: { progress in
        cached.withLock { $0 = progress }
        writes.async {
          guard let data = try? JSONEncoder().encode(progress) else { return }
          try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
          )
          try? data.write(to: url, options: .atomic)
        }
      }
    )
  }

  static func finishWriting() {
    writes.sync {}
  }

  public static let liveValue = file(in: applicationSupport)

  public static let testValue = ProgressStore(load: { Progress() }, save: { _ in })

  public static var applicationSupport: URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
    return (base.first ?? URL.temporaryDirectory).appending(path: "HopTales")
  }
}

extension Progress {
  public mutating func record(
    storyID: String,
    completedSentences sentences: Int,
    wordsRead words: Int,
    stars newStars: Int
  ) {
    stars = newStars
    completedSentences[storyID] = max(completedSentences[storyID] ?? 0, sentences)
    wordsRead[storyID] = max(wordsRead[storyID] ?? 0, words)
  }
}
