import Dependencies
import Foundation
import SQLiteData

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
  public static func database(_ database: any DatabaseWriter) -> ProgressStore {
    ProgressStore(
      load: { (try? database.read { try read(from: $0) }) ?? Progress() },
      save: { progress in
        withErrorReporting {
          try database.write { db in try write(progress, over: read(from: db), in: db) }
        }
      }
    )
  }

  static func read(from db: Database) throws -> Progress {
    let record = try ProgressRecord.find(ProgressRecord.only).fetchOne(db)
    let stories = try StoryProgressRecord.fetchAll(db)
    return Progress(
      stars: record?.stars ?? 0,
      completedSentences: counts(stories, \.completedSentences),
      wordsRead: counts(stories, \.wordsRead),
      journey: record?.journey ?? Journey(),
      baskets: record?.baskets ?? [:],
      outfits: record?.outfits ?? [:]
    )
  }

  private static func counts(
    _ stories: [StoryProgressRecord],
    _ count: KeyPath<StoryProgressRecord, Int>
  ) -> [String: Int] {
    Dictionary(uniqueKeysWithValues: stories.filter { $0[keyPath: count] > 0 }.map {
      ($0.id, $0[keyPath: count])
    })
  }

  static func write(_ progress: Progress, over existing: Progress?, in db: Database) throws {
    let record = ProgressRecord(progress)
    if existing.map(ProgressRecord.init) != record {
      try ProgressRecord.upsert { record }.execute(db)
    }
    let rows = progress.storyRows
    let old = existing?.storyRows ?? [:]
    for (id, row) in rows where old[id] != row {
      try StoryProgressRecord.upsert { row }.execute(db)
    }
    let removed = Set(old.keys).subtracting(rows.keys)
    if !removed.isEmpty {
      try StoryProgressRecord.where { $0.id.in(removed) }.delete().execute(db)
    }
  }

  public static var liveValue: ProgressStore {
    @Dependency(\.defaultDatabase) var database
    return .database(database)
  }

  public static let testValue = ProgressStore(load: { Progress() }, save: { _ in })

  public static var applicationSupport: URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
    return (base.first ?? URL.temporaryDirectory).appending(path: "HopTales")
  }
}

extension Progress {
  var storyRows: [String: StoryProgressRecord] {
    let ids = Set(completedSentences.keys).union(wordsRead.keys)
    return Dictionary(uniqueKeysWithValues: ids.map { id in
      (
        id,
        StoryProgressRecord(
          id: id,
          completedSentences: completedSentences[id] ?? 0,
          wordsRead: wordsRead[id] ?? 0
        )
      )
    })
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
