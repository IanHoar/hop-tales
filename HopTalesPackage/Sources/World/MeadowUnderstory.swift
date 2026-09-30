import Content
import SwiftUI
import UIKit

public struct MeadowUnderstory: View {
  static let bandTop: CGFloat = 0.62
  static let fade: CGFloat = 0.22
  static let step: CGFloat = 0.58
  static let drift: CGFloat = 0.37

  let world: Friend
  let mood: Mood
  let tileWidth: CGFloat

  public init(world: Friend, mood: Mood, tileWidth: CGFloat) {
    self.world = world
    self.mood = mood
    self.tileWidth = tileWidth
  }

  public static func overlap(tileWidth: CGFloat) -> CGFloat {
    let size = MeadowLayer.near.pixelSize
    return tileWidth * size.height * (1 - bandTop) / size.width * fade
  }

  public var body: some View {
    GeometryReader { proxy in
      if let band = Self.band(for: world, tint: mood.landTint), tileWidth > 0 {
        let height = band.size.height * tileWidth / band.size.width
        let rows = Int((proxy.size.height / (height * Self.step)).rounded(.up)) + 1
        let image = Image(uiImage: band)
        Canvas { context, size in
          for row in 0..<rows {
            let top = CGFloat(row) * height * Self.step
            let shift = (CGFloat(row + 1) * Self.drift).truncatingRemainder(dividingBy: 1)
            var x = -shift * tileWidth
            while x < size.width {
              context.draw(image, in: CGRect(x: x, y: top, width: tileWidth, height: height))
              x += tileWidth
            }
          }
        }
      }
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  @MainActor private static var faded: [String: UIImage] = [:]
  @MainActor private static var tinted: [String: UIImage] = [:]

  @MainActor
  static func band(for world: Friend, tint: UIColor) -> UIImage? {
    let name = MeadowLayer.near.asset(in: world)
    let key = "\(name)-\(tint.description)"
    if let cached = tinted[key] { return cached }
    guard let base = fadedBand(name) else { return nil }
    let rect = CGRect(origin: .zero, size: base.size)
    let image = renderer(base.size).image { context in
      base.draw(in: rect)
      tint.setFill()
      context.fill(rect, blendMode: .multiply)
      base.draw(in: rect, blendMode: .destinationIn, alpha: 1)
    }
    tinted[key] = image
    return image
  }

  @MainActor
  private static func fadedBand(_ name: String) -> UIImage? {
    if let cached = faded[name] { return cached }
    guard let art = MeadowArt.image(name), let source = art.cgImage else { return nil }
    let top = Int(CGFloat(source.height) * bandTop)
    let crop = CGRect(x: 0, y: top, width: source.width, height: source.height - top)
    guard let cropped = source.cropping(to: crop) else { return nil }
    let size = CGSize(width: cropped.width, height: cropped.height)
    let image = renderer(size).image { context in
      let cg = context.cgContext
      cg.translateBy(x: 0, y: size.height)
      cg.scaleBy(x: 1, y: -1)
      let fade = size.height * Self.fade
      cg.saveGState()
      cg.clip(to: CGRect(x: 0, y: 0, width: size.width, height: size.height - fade))
      cg.draw(cropped, in: CGRect(origin: .zero, size: size))
      cg.restoreGState()
      let steps = 24
      for index in 0..<steps {
        let slice = fade / CGFloat(steps)
        let y = size.height - fade + CGFloat(index) * slice
        cg.saveGState()
        cg.clip(to: CGRect(x: 0, y: y, width: size.width, height: slice + 0.5))
        cg.setAlpha(1 - CGFloat(index + 1) / CGFloat(steps + 1))
        cg.draw(cropped, in: CGRect(origin: .zero, size: size))
        cg.restoreGState()
      }
    }
    faded[name] = image
    return image
  }

  private static func renderer(_ size: CGSize) -> UIGraphicsImageRenderer {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    return UIGraphicsImageRenderer(size: size, format: format)
  }
}
