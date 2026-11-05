import DependenciesTestSupport
import SnapshotTesting
import SwiftUI
import Testing

@testable import Reading

@MainActor
@Suite(.steady, .snapshots(record: .missing, diffTool: .ksdiff))
struct StoryFinishedSnapshotTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func theFinishedStoryMoment(scheme: ColorScheme) {
    expectSnapshot(of: StoryFinishedPreview(), scheme: scheme)
  }
}
