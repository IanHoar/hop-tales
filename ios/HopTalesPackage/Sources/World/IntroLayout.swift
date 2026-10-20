import CoreGraphics
import UIKit

struct IntroSpot {
  let x: CGFloat
  let top: CGFloat
  let width: CGFloat

  init(_ x: CGFloat, _ top: CGFloat, _ width: CGFloat) {
    self.x = x
    self.top = top
    self.width = width
  }
}

struct IntroLayout {
  static let starSpots = [
    IntroSpot(0.10, 0.11, 16), IntroSpot(0.28, 0.21, 11), IntroSpot(0.77, 0.08, 14),
    IntroSpot(0.64, 0.18, 10), IntroSpot(0.88, 0.27, 12), IntroSpot(0.18, 0.35, 9),
    IntroSpot(0.47, 0.06, 10), IntroSpot(0.55, 0.30, 8)
  ]
  static let offsets: [MeadowLayer: CGFloat] = [.far: 900, .mid: 1400, .near: 600]
  static let night = [UIColor(rgb: 0x1E2A4E), UIColor(rgb: 0x3B4776), UIColor(rgb: 0x6E6D92)]
  static let dawn = [UIColor(rgb: 0x8FA6CF), UIColor(rgb: 0xE7B6A2), UIColor(rgb: 0xF6D6A6)]
  static let day = [UIColor(rgb: 0xBCDCEE), UIColor(rgb: 0xDCEBEF), UIColor(rgb: 0xEEF2E6)]
  static let dimLand = UIColor(white: 0.42, alpha: 1)
  static let nightSaturation: CGFloat = 0.55
  static let hopFrames = 8
  static let hopFrame = CGSize(width: 363, height: 346)
  static let hopUpright: CGFloat = 322
  static let hopFeet: CGFloat = 334

  let meadow: MeadowLayout

  var k: CGFloat { meadow.k }
  var size: CGSize { meadow.size }

  static func launchSize(_ image: CGSize, filling screen: CGSize) -> CGSize {
    guard image.width > 0 else { return image }
    let scale = max(1, screen.width / image.width)
    return CGSize(width: image.width * scale, height: image.height * scale)
  }

  var landDrop: CGFloat { 26 * k }
  var hareFrontHeight: CGFloat { 132 * k }
  var hareSideHeight: CGFloat { 138 * k }
  var hareRunHeight: CGFloat { hareSideHeight * Self.hopFrame.height / Self.hopUpright }
  var hareRunFeet: CGFloat {
    hareRunHeight * (Self.hopFrame.height - Self.hopFeet) / Self.hopFrame.height
  }

  func progress(of layer: MeadowLayer) -> Double {
    Double((Self.offsets[layer] ?? 0) * meadow.scale / layer.speed)
  }

  func y(_ top: CGFloat) -> CGFloat { size.height - top }
}
