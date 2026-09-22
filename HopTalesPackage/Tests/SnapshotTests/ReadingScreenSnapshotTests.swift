import SnapshotTesting
import SwiftUI
import Testing
import UIKit

@testable import Reading

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff))
struct ReadingScreenSnapshotTests {
  static let largePhone = ViewImageConfig(
    safeArea: UIEdgeInsets(top: 62, left: 0, bottom: 34, right: 0),
    size: CGSize(width: 440, height: 956),
    traits: UITraitCollection(userInterfaceIdiom: .phone)
  )

  static let smallPhone = ViewImageConfig(
    safeArea: UIEdgeInsets(top: 50, left: 0, bottom: 34, right: 0),
    size: CGSize(width: 375, height: 812),
    traits: UITraitCollection(userInterfaceIdiom: .phone)
  )

  @Test func theChromeStacksWithoutOverlapOnALargePhone() {
    expectSnapshot(
      of: ReadingScreenPreview(),
      as: .image(layout: .device(config: Self.largePhone)),
      named: "large"
    )
  }

  @Test func theChromeStacksWithoutOverlapOnASmallPhone() {
    expectSnapshot(
      of: ReadingScreenPreview(),
      as: .image(layout: .device(config: Self.smallPhone)),
      named: "small"
    )
  }
}
