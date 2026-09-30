import Content
import DesignSystem
import Foundation
import SnapshotTesting
import SwiftUI
import Testing
import UIKit

@testable import Home
@testable import Reading

@MainActor
@Suite(
  .enabled(if: ProcessInfo.processInfo.environment["STORE_SCREENSHOTS"] == "1"),
  .everyLookPainted
)
struct StoreScreenshotTests {
  nonisolated static let stories = [
    "bob-bug|3|2", "button-big-story|1|3", "barnacle-shells|0|1", "rain-on-the-field|1|3"
  ]
  nonisolated static let devices = ["phone", "pad"]

  static func config(_ device: String) -> ViewImageConfig {
    device == "pad"
      ? ViewImageConfig(
        safeArea: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0),
        size: CGSize(width: 1032, height: 1376),
        traits: UITraitCollection {
          $0.userInterfaceIdiom = .pad
          $0.displayScale = 2
          $0.userInterfaceStyle = .light
        }
      )
      : ViewImageConfig(
        safeArea: UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0),
        size: CGSize(width: 440, height: 956),
        traits: UITraitCollection {
          $0.userInterfaceIdiom = .phone
          $0.displayScale = 3
          $0.userInterfaceStyle = .light
        }
      )
  }

  static func output(file: StaticString = #filePath) -> String {
    URL(fileURLWithPath: "\(file)")
      .deletingLastPathComponent()
      .appendingPathComponent("../../../build/store-screenshots/raw")
      .standardized.path
  }

  func shoot(_ view: some View, _ name: String, device: String) {
    var body = AnyView(
      view
        .environment(\.freezesMotion, true)
        .environment(\.hidesDebugControls, true)
        .environment(\.colorScheme, .light)
    )
    if device == "pad" {
      body = AnyView(
        body
          .environment(\.horizontalSizeClass, .regular)
          .environment(\.verticalSizeClass, .regular)
      )
    }
    _ = verifySnapshot(
      of: body,
      as: .image(layout: .device(config: Self.config(device))),
      named: "\(device)-\(name)",
      record: .all,
      snapshotDirectory: Self.output(),
      testName: "shot"
    )
  }

  @Test(arguments: stories, devices)
  func story(key: String, device: String) throws {
    let parts = key.split(separator: "|").map(String.init)
    let story = try #require(StoryLibrary[parts[0]])
    let moment = ReadingScreenPreview.Moment.at(
      sentence: try #require(Int(parts[1])),
      word: try #require(Int(parts[2]))
    )
    shoot(
      ReadingScreenPreview(story: story, moment: moment, friend: story.friend),
      parts[0],
      device: device
    )
  }

  @Test(arguments: devices)
  func screens(device: String) throws {
    let config = Self.config(device)
    let full = try #require(config.size)
    let size = CGSize(
      width: full.width,
      height: full.height - config.safeArea.top - config.safeArea.bottom
    )
    shoot(HomePreview(.midway, size: size), "home", device: device)
    shoot(ReadingScreenPreview(moment: .newFriend), "new-friend", device: device)
  }
}
