import SpriteKit
import UIKit

@MainActor
enum MeadowArt {
  private static var images: [String: UIImage] = [:]
  private static var textures: [String: SKTexture] = [:]

  static func image(_ name: String) -> UIImage? {
    if let cached = images[name] { return cached }
    let url = ["png", "webp"].lazy
      .compactMap { Bundle.module.url(forResource: name, withExtension: $0) }
      .first
    guard let url, let image = UIImage(contentsOfFile: url.path) else { return nil }
    images[name] = image
    return image
  }

  static func texture(_ name: String) -> SKTexture {
    if let cached = textures[name] { return cached }
    let texture = image(name).map(SKTexture.init(image:)) ?? SKTexture()
    textures[name] = texture
    return texture
  }

  static func gradient(_ colors: [UIColor], size: CGSize) -> UIImage {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    return UIGraphicsImageRenderer(size: size, format: format).image { context in
      let cgColors = colors.map(\.cgColor) as CFArray
      let locations: [CGFloat] = [0, 0.55, 1]
      guard
        let gradient = CGGradient(
          colorsSpace: CGColorSpaceCreateDeviceRGB(),
          colors: cgColors,
          locations: locations
        )
      else { return }
      context.cgContext.drawLinearGradient(
        gradient,
        start: .zero,
        end: CGPoint(x: 0, y: size.height),
        options: []
      )
    }
  }
}

struct SeededRandom: RandomNumberGenerator {
  private var state: UInt64

  init(seed: Int) {
    state = UInt64(bitPattern: Int64(seed)) &+ 0x9E37_79B9_7F4A_7C15
  }

  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var value = state
    value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
    value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
    return value ^ (value >> 31)
  }
}
