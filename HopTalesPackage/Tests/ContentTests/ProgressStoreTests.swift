import Foundation
import SQLiteData
import Testing

@testable import Content

struct ProgressStoreTests {
  private func database(importingFrom legacy: URL? = nil) throws -> DatabaseQueue {
    let database = try DatabaseQueue()
    try HopTalesDatabase.migrator(importingFrom: legacy).migrate(database)
    return database
  }

  @Test func anEmptyDatabaseReadsAsFreshProgress() throws {
    #expect(ProgressStore.database(try database()).load() == Content.Progress())
  }

  @Test func whatIsSavedComesBack() throws {
    let store = ProgressStore.database(try database())
    var progress = Content.Progress(stars: 41, completedSentences: ["castle-road": 3])
    progress.journey = Journey(starting: .frog)
    var basket = Basket()
    basket.total = 5
    basket.golden = 1
    progress.baskets[.frog] = basket
    progress.outfits[.frog] = [.head: "straw-hat"]
    progress.wordsRead = ["castle-road": 18, "pond": 4]
    store.save(progress)
    #expect(store.load() == progress)
  }

  @Test func onlyTheStoriesThatChangedAreWritten() throws {
    let database = try database()
    let store = ProgressStore.database(database)
    store.save(Content.Progress(completedSentences: ["a": 1, "b": 2], wordsRead: ["a": 3, "b": 4]))
    let changes = try database.write { db in
      let before = db.totalChangesCount
      try ProgressStore.write(
        Content.Progress(completedSentences: ["a": 1, "b": 5], wordsRead: ["a": 3, "b": 9]),
        over: ProgressStore.read(from: db),
        in: db
      )
      return db.totalChangesCount - before
    }
    #expect(changes == 1)
  }

  @Test func aResetStoryIsRemoved() throws {
    let store = ProgressStore.database(try database())
    store.save(Content.Progress(completedSentences: ["a": 1], wordsRead: ["a": 3]))
    store.save(Content.Progress())
    #expect(store.load() == Content.Progress())
  }

  @Test func progressFromBeforeTheDatabaseIsImported() throws {
    let folder = URL.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let progress = Content.Progress(
      stars: 12, completedSentences: ["pond": 2], wordsRead: ["pond": 7]
    )
    try JSONEncoder().encode(progress).write(to: folder.appending(path: "progress.json"))
    try JSONEncoder().encode(Profile(childName: "Maya", startingFriend: .hare))
      .write(to: folder.appending(path: "profile.json"))
    let database = try database(importingFrom: folder)
    #expect(ProgressStore.database(database).load() == progress)
    #expect(ProfileStore.database(database, drafts: folder).load()?.childName == "Maya")
  }

  @Test func recordingNeverMovesAStoryBackwards() {
    var progress = Content.Progress()
    progress.record(storyID: "castle-road", completedSentences: 4, wordsRead: 20, stars: 30)
    progress.record(storyID: "castle-road", completedSentences: 2, wordsRead: 9, stars: 30)
    #expect(progress.completedSentences["castle-road"] == 4)
    #expect(progress.wordsRead["castle-road"] == 20)
  }
}
