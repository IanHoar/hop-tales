import Foundation
import SpriteKit
import Testing
import UIKit

@testable import World

@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.environment["LAUNCH_ART"] == "1"))
struct LaunchArtTests {
  static let landscape = CGSize(width: 951, height: 669)
  static let reference = CGSize(width: 669, height: 951)

  static func output(file: StaticString = #filePath) -> URL {
    URL(fileURLWithPath: "\(file)")
      .deletingLastPathComponent()
      .appendingPathComponent(
        "../../../HopTales/Assets.xcassets/LaunchImageOpen.imageset/launch-open@2x.png"
      )
      .standardized
  }

  @Test func renderTheOpenDuoLaunchStill() throws {
    let canvas = UIGraphicsImageRenderer(size: Self.reference).image { _ in }
    let scene = IntroScene(size: Self.landscape, launchImage: canvas, stretchesLaunch: true)
    scene.launch?.isHidden = true
    let view = SKView(frame: CGRect(origin: .zero, size: Self.landscape))
    view.contentScaleFactor = 2
    view.presentScene(scene)
    let frame = try #require(view.texture(from: scene)).cgImage()
    let format = UIGraphicsImageRendererFormat()
    format.scale = 2
    format.opaque = true
    let still = UIGraphicsImageRenderer(size: Self.reference, format: format).image { _ in
      UIImage(cgImage: frame).draw(in: CGRect(origin: .zero, size: Self.reference))
    }
    try #require(still.pngData()).write(to: Self.output())
  }
}
