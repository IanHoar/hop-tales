import Content
import UIKit

@MainActor
public enum MeadowPostcard {
  private struct Key: Hashable {
    let mood: Mood
    let width: Int
    let height: Int
    let progress: Int
    let framing: MeadowFraming
    let world: Friend
  }

  private static var cache: [Key: UIImage] = [:]
  private static var tinted: [String: UIImage] = [:]

  public static func image(
    mood: Mood,
    size: CGSize,
    progress: Double = 0,
    framing: MeadowFraming = .wide,
    world: Friend = .hare
  ) -> UIImage {
    let key = Key(
      mood: mood,
      width: Int(size.width),
      height: Int(size.height),
      progress: Int(progress),
      framing: framing,
      world: world
    )
    if let cached = cache[key] { return cached }
    let layout = MeadowLayout(size: size, framing: framing)
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 2
    let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
      MeadowArt.gradient(mood.sky.style.gradient, size: size)
        .draw(in: CGRect(origin: .zero, size: size))
      drawSky(mood, layout: layout)
      for layer in MeadowLayer.allCases {
        drawLayer(layer, in: world, mood: mood, layout: layout, progress: progress)
      }
      let weather = mood.weather.style
      if weather.overlay > 0 {
        UIColor(rgb: 0x4E5A6E).withAlphaComponent(weather.overlay).setFill()
        context.fill(CGRect(origin: .zero, size: size), blendMode: .normal)
      }
      if weather.rain { drawRain(size) }
    }
    cache[key] = image
    return image
  }

  private static func drawSky(_ mood: Mood, layout: MeadowLayout) {
    let sky = mood.sky.style
    let size = layout.size
    if sky.stars > 0 {
      for star in MeadowStars.field(for: layout) {
        draw(star.asset, centre: star.centre, width: star.width, alpha: sky.stars)
      }
    }
    if sky.moon > 0 {
      draw("sky-moon", centre: layout.moonCentre, width: layout.moonSize.width, alpha: sky.moon)
    }
    if sky.sun * mood.weather.style.sun > 0 {
      let width = layout.sunWidth
      let centre = CGPoint(
        x: size.width * 0.24,
        y: layout.sunTop + width / 2 + sky.sunDrop * layout.k
      )
      draw("sky-sun", centre: centre, width: width, alpha: sky.sun)
    }
    let weather = mood.weather.style
    let clouds: [(name: String, spot: CGPoint)] = [
      ("sky-cloud-1", CGPoint(x: 0.18, y: 70)), ("sky-cloud-3", CGPoint(x: 0.72, y: 140)),
      ("sky-storm-1", CGPoint(x: 0.3, y: 100)), ("sky-storm-2", CGPoint(x: 0.82, y: 60))
    ]
    for cloud in clouds {
      let alpha = (cloud.name.hasPrefix("sky-storm") ? weather.stormClouds : weather.fairClouds)
        * sky.clouds
      guard alpha > 0 else { continue }
      let width = (MeadowArt.image(cloud.name)?.size.width ?? 500) * 0.5 * layout.k
      let centre = CGPoint(x: cloud.spot.x * size.width, y: cloud.spot.y * layout.k)
      draw(cloud.name, centre: centre, width: width, alpha: alpha)
    }
  }

  private static func draw(_ name: String, centre: CGPoint, width: CGFloat, alpha: CGFloat) {
    guard let image = MeadowArt.image(name) else { return }
    let height = width * image.size.height / max(image.size.width, 1)
    image.draw(
      in: CGRect(x: centre.x - width / 2, y: centre.y - height / 2, width: width, height: height),
      blendMode: .normal,
      alpha: alpha
    )
  }

  private static func drawLayer(
    _ layer: MeadowLayer,
    in world: Friend,
    mood: Mood,
    layout: MeadowLayout,
    progress: Double
  ) {
    let detail: CGFloat = layout.framing == .wide ? 4 : 2
    guard let image = tintedLayer(layer, in: world, mood: mood, detail: detail) else { return }
    let tile = layout.tileSize(of: layer)
    let offset = layout.offset(of: layer, progress: progress)
    for index in 0..<layout.tileCount(of: layer) {
      image.draw(in: CGRect(
        x: offset + CGFloat(index) * tile.width,
        y: layout.top(of: layer),
        width: tile.width,
        height: tile.height
      ))
    }
  }

  private static func tintedLayer(
    _ layer: MeadowLayer,
    in world: Friend,
    mood: Mood,
    detail: CGFloat
  ) -> UIImage? {
    let asset = layer.asset(in: world)
    let key = "\(asset)-\(mood.sky.rawValue)-\(mood.weather.rawValue)-\(detail)"
    if let cached = tinted[key] { return cached }
    guard let source = MeadowArt.image(asset) else { return nil }
    let size = CGSize(width: source.size.width / detail, height: source.size.height / detail)
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
      let rect = CGRect(origin: .zero, size: size)
      source.draw(in: rect)
      mood.tint(for: layer).setFill()
      context.fill(rect, blendMode: .multiply)
      source.draw(in: rect, blendMode: .destinationIn, alpha: 1)
    }
    tinted[key] = image
    return image
  }

  private static func drawRain(_ size: CGSize) {
    var random = SeededRandom(seed: 7)
    UIColor(white: 1, alpha: 0.45).setStroke()
    let path = UIBezierPath()
    path.lineWidth = 1.2
    for _ in 0..<Int(size.width * size.height / 2600) {
      let x = CGFloat.random(in: -40...size.width, using: &random)
      let y = CGFloat.random(in: 0...size.height, using: &random)
      path.move(to: CGPoint(x: x, y: y))
      path.addLine(to: CGPoint(x: x + 6, y: y + 22))
    }
    path.stroke()
  }
}
