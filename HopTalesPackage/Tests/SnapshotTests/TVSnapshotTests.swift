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

  static func traits(_ scheme: ColorScheme) -> UITraitCollection {
    UITraitCollection {
      $0.displayScale = 1
      $0.userInterfaceStyle = scheme == .dark ? .dark : .light
    }
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func theTVFollowsTheStory(scheme: ColorScheme) {
    var state = Reading.State(story: StoryLibrary.all[0])
    state.sentenceIndex = 1
    state.wordIndex = 2
    state.stars = 9
    let store = Store(initialState: state) { Reading() }
    expectSnapshot(
      of: TVReadingScreen(store: store)
        .environment(\.freezesMotion, true)
        .environment(\.colorScheme, scheme),
      as: .image(
        layout: .fixed(width: Self.tv.width, height: Self.tv.height),
        traits: Self.traits(scheme)
      ),
      named: "reading-\(scheme)"
    )
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func theTVWaitsForAStory(scheme: ColorScheme) {
    expectSnapshot(
      of: TVWaitingScreen(childName: "Maya")
        .environment(\.freezesMotion, true)
        .environment(\.colorScheme, scheme),
      as: .image(
        layout: .fixed(width: Self.tv.width, height: Self.tv.height),
        traits: Self.traits(scheme)
      ),
      named: "waiting-\(scheme)"
    )
  }
}
