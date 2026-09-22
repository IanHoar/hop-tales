import Dependencies
import Foundation

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

  public static func file(in directory: URL) -> ProgressStore {
    let url = directory.appending(path: fileName)
    return ProgressStore(
      load: {
        guard let data = try? Data(contentsOf: url) else { return Progress() }
        return (try? JSONDecoder().decode(Progress.self, from: data)) ?? Progress()
      },
      save: { progress in
        guard let data = try? JSONEncoder().encode(progress) else { return }
        try? FileManager.default.createDirectory(
          at: directory,
          withIntermediateDirectories: true
        )
        try? data.write(to: url, options: .atomic)
      }
    )
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
