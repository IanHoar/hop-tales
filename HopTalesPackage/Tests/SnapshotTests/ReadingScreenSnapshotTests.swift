import DesignSystem
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

  static let padLandscape = ViewImageConfig(
    safeArea: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0),
    size: CGSize(width: 1194, height: 834),
    traits: UITraitCollection(userInterfaceIdiom: .pad)
  )

  static let padPortrait = ViewImageConfig(
    safeArea: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0),
    size: CGSize(width: 834, height: 1194),
    traits: UITraitCollection(userInterfaceIdiom: .pad)
  )

  static func device(_ config: ViewImageConfig, _ scheme: ColorScheme) -> ViewImageConfig {
    var config = config
    config.traits = UITraitCollection(traitsFrom: [
      config.traits,
      UITraitCollection(userInterfaceStyle: scheme == .dark ? .dark : .light)
    ])
    return config
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func theChromeStacksWithoutOverlapOnALargePhone(scheme: ColorScheme) {
    expectSnapshot(
      of: ReadingScreenPreview()
        .environment(\.freezesMotion, true)
        .environment(\.colorScheme, scheme),
      as: .image(layout: .device(config: Self.device(Self.largePhone, scheme))),
      named: "large-\(scheme)"
    )
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func theChromeStacksWithoutOverlapOnASmallPhone(scheme: ColorScheme) {
    expectSnapshot(
      of: ReadingScreenPreview()
        .environment(\.freezesMotion, true)
        .environment(\.colorScheme, scheme),
      as: .image(layout: .device(config: Self.device(Self.smallPhone, scheme))),
      named: "small-\(scheme)"
    )
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func theIPadLaysTheChromeOutInLandscape(scheme: ColorScheme) {
    expectSnapshot(
      of: ReadingScreenPreview()
        .environment(\.freezesMotion, true)
        .environment(\.colorScheme, scheme)
        .environment(\.horizontalSizeClass, .regular)
        .environment(\.verticalSizeClass, .regular),
      as: .image(layout: .device(config: Self.device(Self.padLandscape, scheme))),
      named: "pad-landscape-\(scheme)"
    )
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func theIPadLaysTheChromeOutInPortrait(scheme: ColorScheme) {
    expectSnapshot(
      of: ReadingScreenPreview()
        .environment(\.freezesMotion, true)
        .environment(\.colorScheme, scheme)
        .environment(\.horizontalSizeClass, .regular)
        .environment(\.verticalSizeClass, .regular),
      as: .image(layout: .device(config: Self.device(Self.padPortrait, scheme))),
      named: "pad-portrait-\(scheme)"
    )
  }
}
