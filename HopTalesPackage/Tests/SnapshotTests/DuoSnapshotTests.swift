import DesignSystem
import SnapshotTesting
import SwiftUI
import Testing
import UIKit

@testable import Home
@testable import Onboarding
@testable import Reading

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff), .everyLookPainted)
struct DuoSnapshotTests {
  enum Fold: String, CaseIterable {
    case folded
    case open

    @MainActor var config: ViewImageConfig {
      switch self {
      case .folded:
        ViewImageConfig(
          safeArea: UIEdgeInsets(top: 0, left: 0, bottom: 34, right: 84),
          size: CGSize(width: 466, height: 678),
          traits: Self.traits
        )
      case .open:
        ViewImageConfig(
          safeArea: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0),
          size: CGSize(width: 669, height: 951),
          traits: Self.traits
        )
      }
    }

    @MainActor static var traits: UITraitCollection {
      UITraitCollection {
        $0.userInterfaceIdiom = .phone
        $0.horizontalSizeClass = .compact
        $0.verticalSizeClass = .regular
      }
    }

    @MainActor var content: CGSize {
      let config = config
      let size = config.size ?? .zero
      return CGSize(
        width: size.width - config.safeArea.left - config.safeArea.right,
        height: size.height - config.safeArea.top - config.safeArea.bottom
      )
    }
  }

  nonisolated static let cases: [(Fold, ColorScheme)] = [
    (.folded, .light), (.folded, .dark), (.open, .light), (.open, .dark)
  ]

  func shoot(
    _ view: some View,
    _ fold: Fold,
    _ scheme: ColorScheme,
    named name: String,
    testName: String = #function
  ) {
    let config = ReadingScreenSnapshotTests.device(fold.config, scheme)
    expectSnapshot(
      of: view
        .environment(\.freezesMotion, true)
        .environment(\.colorScheme, scheme)
        .environment(\.horizontalSizeClass, .compact)
        .environment(\.verticalSizeClass, .regular),
      as: .image(layout: .device(config: config)),
      named: "\(name)-\(fold.rawValue)-\(scheme)",
      testName: testName
    )
  }

  @Test(arguments: cases)
  func reading(fold: Fold, scheme: ColorScheme) {
    shoot(ReadingScreenPreview(moment: .midPage), fold, scheme, named: "reading")
  }

  @Test(arguments: cases)
  func home(fold: Fold, scheme: ColorScheme) {
    shoot(HomePreview(.midway, size: fold.content), fold, scheme, named: "home")
  }

  @Test(arguments: cases)
  func onboarding(fold: Fold, scheme: ColorScheme) {
    shoot(OnboardingPreview(.friend, size: fold.content), fold, scheme, named: "onboarding")
  }

  nonisolated static let halfOpen: [(String, CGRect)] = [
    ("laptop", CGRect(x: 0, y: 433, width: 669, height: 40)),
    ("book", CGRect(x: 314, y: 0, width: 40, height: 907))
  ]

  @Test(arguments: halfOpen)
  func onboardingHalfOpen(posture: String, fold: CGRect) {
    for step in [Onboarding.Step.cloud, .friend] {
      shoot(
        OnboardingPreview(step, size: Fold.open.content)
          .environment(\.simulatedFold, DesignSystem.Fold(fold)),
        .open,
        .light,
        named: "onboarding-\(step)-\(posture)"
      )
    }
  }
}
