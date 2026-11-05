import SpriteKit
import Synchronization
import UIKit

enum MeadowArt {
  private static let images = Mutex<[String: UIImage]>([:])
  @MainActor private static var textures: [String: SKTexture] = [:]

  static func image(_ name: String) -> UIImage? {
    if let cached = images.withLock({ $0[name] }) { return cached }
    let url = ["png", "webp"].lazy
      .compactMap { Bundle.module.url(forResource: name, withExtension: $0) }
      .first
    guard let url, let image = UIImage(contentsOfFile: url.path) else { return nil }
    images.withLock { $0[name] = image }
    return image
  }

  static func decoded(_ name: String) -> UIImage? {
    guard let image = image(name) else { return nil }
    return image.preparingForDisplay() ?? image
  }

  @MainActor
  static func texture(_ name: String) -> SKTexture {
    if let cached = textures[name] { return cached }
    let texture = image(name).map(SKTexture.init(image:)) ?? SKTexture()
    textures[name] = texture
    return texture
  }

  private static let silhouettes = Mutex<[String: UIImage]>([:])

  static func silhouette(_ name: String) -> UIImage? {
    if let cached = silhouettes.withLock({ $0[name] }) { return cached }
    guard let source = image(name) else { return nil }
    let rect = CGRect(origin: .zero, size: source.size)
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = source.scale
    let shape = UIGraphicsImageRenderer(size: source.size, format: format).image { context in
      source.draw(in: rect)
      UIColor.white.setFill()
      context.fill(rect, blendMode: .sourceAtop)
    }
    silhouettes.withLock { $0[name] = shape }
    return shape
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
