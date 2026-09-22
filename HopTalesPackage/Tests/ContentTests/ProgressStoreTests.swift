import Foundation
import Testing

@testable import Content

struct ProgressStoreTests {
  private func directory() -> URL {
    URL.temporaryDirectory.appending(path: UUID().uuidString)
  }

  @Test func anEmptyDirectoryReadsAsFreshProgress() {
    #expect(ProgressStore.file(in: directory()).load() == Content.Progress())
  }

  @Test func whatIsSavedComesBack() {
    let store = ProgressStore.file(in: directory())
    store.save(Content.Progress(stars: 41, completedSentences: ["castle-road": 3]))
    let loaded = store.load()
    #expect(loaded.stars == 41)
    #expect(loaded.completedSentences["castle-road"] == 3)
  }

  @Test func rubbishOnDiskReadsAsFreshProgressRatherThanCrashing() throws {
    let folder = directory()
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    try Data("not json".utf8).write(to: folder.appending(path: ProgressStore.fileName))
    #expect(ProgressStore.file(in: folder).load() == Content.Progress())
  }

  @Test func recordingNeverMovesAStoryBackwards() {
    var progress = Content.Progress()
    progress.record(storyID: "castle-road", completedSentences: 4, wordsRead: 20, stars: 30)
    progress.record(storyID: "castle-road", completedSentences: 2, wordsRead: 9, stars: 30)
    #expect(progress.completedSentences["castle-road"] == 4)
    #expect(progress.wordsRead["castle-road"] == 20)
  }
}
