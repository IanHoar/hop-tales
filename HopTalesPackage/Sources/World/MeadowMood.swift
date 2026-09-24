import Content
import UIKit

struct SkyStyle {
  let gradient: [UIColor]
  let tints: [MeadowLayer: UIColor]
  let stars: CGFloat
  let moon: CGFloat
  let sun: CGFloat
  let sunDrop: CGFloat
  let clouds: CGFloat
}

struct WeatherStyle {
  let fairClouds: CGFloat
  let stormClouds: CGFloat
  let overlay: CGFloat
  let dim: CGFloat
  let rain: Bool
  let lightning: Bool

  var sun: CGFloat { overlay > 0 ? 0 : 1 }
}

extension UIColor {
  convenience init(rgb: UInt32) {
    self.init(
      red: CGFloat((rgb >> 16) & 0xFF) / 255,
      green: CGFloat((rgb >> 8) & 0xFF) / 255,
      blue: CGFloat(rgb & 0xFF) / 255,
      alpha: 1
    )
  }

  func dimmed(_ factor: CGFloat) -> UIColor {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return UIColor(red: red * factor, green: green * factor, blue: blue * factor, alpha: alpha)
  }
}

extension Sky {
  var style: SkyStyle {
    switch self {
    case .day:
      style([0xBCDCEE, 0xDCEBEF, 0xEEF2E6], [0xFFFFFF, 0xFFFFFF, 0xFFFFFF], sun: 1)
    case .golden:
      style(
        [0xF0C9A4, 0xF7DDB8, 0xFBEBCB], [0xFCD6AA, 0xFFDEB4, 0xFFE8C4], sun: 1, drop: 70
      )
    case .dusk:
      style(
        [0x7F74A6, 0xC98FA2, 0xF0B48E], [0xC4A0C8, 0xD6ACBE, 0xE8BEBE],
        stars: 0.35, moon: 0.5, sun: 0.6, drop: 150
      )
    case .night:
      style(
        [0x18223F, 0x2C3A63, 0x46557E], [0x5C6CA0, 0x6070A0, 0x6876A0],
        stars: 1, moon: 1, clouds: 0.35
      )
    }
  }

  private func style(
    _ gradient: [UInt32],
    _ tints: [UInt32],
    stars: CGFloat = 0,
    moon: CGFloat = 0,
    sun: CGFloat = 0,
    drop: CGFloat = 0,
    clouds: CGFloat = 1
  ) -> SkyStyle {
    SkyStyle(
      gradient: gradient.map(UIColor.init(rgb:)),
      tints: [
        .far: UIColor(rgb: tints[0]), .mid: UIColor(rgb: tints[1]), .near: UIColor(rgb: tints[2])
      ],
      stars: stars,
      moon: moon,
      sun: sun,
      sunDrop: drop,
      clouds: clouds
    )
  }
}

extension Weather {
  var style: WeatherStyle {
    switch self {
    case .clear:
      WeatherStyle(
        fairClouds: 0.55, stormClouds: 0, overlay: 0, dim: 1, rain: false, lightning: false
      )
    case .clouds:
      WeatherStyle(
        fairClouds: 1, stormClouds: 0.35, overlay: 0, dim: 1, rain: false, lightning: false
      )
    case .storm:
      WeatherStyle(
        fairClouds: 0.2, stormClouds: 1, overlay: 0.34, dim: 0.74, rain: false, lightning: true
      )
    case .rain:
      WeatherStyle(
        fairClouds: 0, stormClouds: 1, overlay: 0.28, dim: 0.74, rain: true, lightning: false
      )
    }
  }
}

extension Mood {
  func tint(for layer: MeadowLayer) -> UIColor {
    (sky.style.tints[layer] ?? .white).dimmed(weather.style.dim)
  }
}
