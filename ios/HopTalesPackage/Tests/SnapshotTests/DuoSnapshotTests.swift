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
    case openPortrait

    @MainActor var config: ViewImageConfig {
      switch self {
      case .folded:
        ViewImageConfig(
          safeArea: UIEdgeInsets(top: 0, left: 0, bottom: 34, right: 84),
          size: CGSize(width: 466, height: 678),
          traits: Self.traits(.compact)
        )
      case .open:
        ViewImageConfig(
          safeArea: UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 84),
          size: CGSize(width: 951, height: 669),
          traits: Self.traits(.regular)
        )
      case .openPortrait:
        ViewImageConfig(
          safeArea: UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0),
          size: CGSize(width: 669, height: 951),
          traits: Self.traits(.regular)
        )
      }
    }

    var horizontalSizeClass: UserInterfaceSizeClass {
      self == .folded ? .compact : .regular
    }

    @MainActor static func traits(_ width: UIUserInterfaceSizeClass) -> UITraitCollection {
      UITraitCollection {
        $0.userInterfaceIdiom = .phone
        $0.horizontalSizeClass = width
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

  nonisolated static let cases: [(Fold, ColorScheme)] = Fold.allCases.flatMap { fold in
    [(fold, ColorScheme.light), (fold, .dark)]
  }

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
        .environment(\.horizontalSizeClass, fold.horizontalSizeClass)
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
    shoot(OnboardingPreview(.ahead, size: fold.content), fold, scheme, named: "onboarding")
  }

  struct Posture: Sendable {
    let name: String
    let fold: Fold
    let crease: CGRect
  }

  nonisolated static let postures = [
    Posture(
      name: "laptop", fold: .openPortrait, crease: CGRect(x: 0, y: 433, width: 669, height: 40)
    ),
    Posture(name: "book", fold: .open, crease: CGRect(x: 455, y: 0, width: 40, height: 649))
  ]

  @Test(arguments: postures)
  func onboardingHalfOpen(posture: Posture) {
    for step in [Onboarding.Step.cloud, .ahead] {
      shoot(
        OnboardingPreview(step, size: posture.fold.content)
          .environment(\.simulatedFold, DesignSystem.Fold(posture.crease)),
        posture.fold,
        .light,
        named: "onboarding-\(step)-\(posture.name)"
      )
    }
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func homeHalfOpen(scheme: ColorScheme) {
    let book = Self.postures[1]
    shoot(
      HomePreview(.midway, size: book.fold.content)
        .environment(\.simulatedFold, DesignSystem.Fold(book.crease)),
      book.fold,
      scheme,
      named: "home-book"
    )
  }
}
