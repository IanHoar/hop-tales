import Foundation
import SQLiteData
import Testing

@testable import Content

struct ProfileStoreTests {
  func store() throws -> ProfileStore {
    let database = try DatabaseQueue()
    try HopTalesDatabase.migrator().migrate(database)
    return ProfileStore.database(
      database,
      drafts: URL.temporaryDirectory.appending(path: UUID().uuidString)
    )
  }

  @Test func aFreshInstallHasNoProfileAndNoDraft() throws {
    let store = try store()
    #expect(store.load() == nil)
    #expect(store.loadDraft() == nil)
  }

  @Test func aDraftSurvivesUntilTheProfileIsSaved() throws {
    let store = try store()
    let draft = ProfileDraft(childName: "Maya", step: 2)
    store.saveDraft(draft)
    #expect(store.loadDraft() == draft)

    let profile = Profile(
      childName: "Maya", startingFriend: .crab, accent: .british, voiceID: "v1", theme: .dark,
      soundButtons: true
    )
    store.save(profile)
    #expect(store.load() == profile)
    #expect(store.loadDraft() == nil)
  }

  @Test func erasingForgetsTheProfile() throws {
    let store = try store()
    store.save(Profile(childName: "Maya"))
    store.erase()
    #expect(store.load() == nil)
  }
}
