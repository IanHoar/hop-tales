import ComposableArchitecture2
import Content
import DesignSystem
import SnapshotTesting
import SwiftUI
import Testing

@testable import Reading

@MainActor
struct TVSnapshotTests {
  static let tv = CGSize(width: 1920, height: 1080)

  @Test func theTVFollowsTheStory() {
    var state = Reading.State(story: StoryLibrary.all[0])
    state.sentenceIndex = 1
    state.wordIndex = 2
    state.stars = 9
    let store = Store(initialState: state) { Reading() }
    expectSnapshot(
      of: TVReadingScreen(store: store).environment(\.freezesMotion, true),
      as: .image(layout: .fixed(width: Self.tv.width, height: Self.tv.height)),
      named: "reading"
    )
  }

  @Test func theTVWaitsForAStory() {
    expectSnapshot(
      of: TVWaitingScreen(childName: "Maya").environment(\.freezesMotion, true),
      as: .image(layout: .fixed(width: Self.tv.width, height: Self.tv.height)),
      named: "waiting"
    )
  }
}
