import Foundation
import Testing

@testable import Content

struct ProfileStoreTests {
  func store() -> ProfileStore {
    ProfileStore.file(in: URL.temporaryDirectory.appending(path: UUID().uuidString))
  }

  @Test func aFreshInstallHasNoProfileAndNoDraft() {
    let store = store()
    #expect(store.load() == nil)
    #expect(store.loadDraft() == nil)
  }

  @Test func aDraftSurvivesUntilTheProfileIsSaved() {
    let store = store()
    let draft = ProfileDraft(childName: "Maya", step: 2)
    store.saveDraft(draft)
    #expect(store.loadDraft() == draft)

    let profile = Profile(childName: "Maya")
    store.save(profile)
    #expect(store.load() == profile)
    #expect(store.loadDraft() == nil)
  }
}
