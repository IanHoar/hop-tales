import CoreGraphics
import UIKit

@MainActor
public enum WorldPostcard {
  struct Key: Hashable {
    let tone: WorldArt.Tone
    let progress: Double
    let scale: CGFloat
    let width: CGFloat
    let height: CGFloat
    let top: CGFloat
  }

  private static var cache: [Key: UIImage] = [:]

  public static func progress(for stage: WorldStage) -> Double {
    switch stage {
    case .meadow: 0
    case .castle: 1000
    case .dragon: 1950
    }
  }

  public static func image(
    tone: WorldArt.Tone,
    progress: Double,
    scale: CGFloat,
    size: CGSize,
    top: CGFloat = 0
  ) -> UIImage? {
    let key = Key(
      tone: tone,
      progress: progress,
      scale: scale,
      width: size.width,
      height: size.height,
      top: top
    )
    if let cached = cache[key] { return cached }
    let offsets = LayerOffsets(progress: progress)
    let layers: [(WorldArt.Layer, Double)] = [
      (.sky, 0), (.far, offsets.far), (.mid, offsets.mid), (.near, offsets.near)
    ]
    let image = UIGraphicsImageRenderer(size: size).image { context in
      for (layer, offset) in layers {
        WorldArt(layer, tone).draw(
          in: context.cgContext,
          origin: CGPoint(x: CGFloat(offset) * scale, y: -top),
          scale: scale
        )
      }
    }
    cache[key] = image
    return image
  }
}

@MainActor
public enum CastPortrait {
  private static var cache: [WorldStage: UIImage] = [:]

  static func parts(for stage: WorldStage) -> [String] {
    switch stage {
    case .meadow:
      [
        "fox-shadow", "fox-tail", "fox-leg-far-rear", "fox-leg-far-front", "fox-body",
        "fox-leg-near-rear", "fox-leg-near-front", "fox-scarf", "fox-head-happy", "fox-wrap"
      ]
    case .castle: ["knight-idle"]
    case .dragon: ["dragon-body-idle", "dragon-wing"]
    }
  }

  public static func image(for stage: WorldStage) -> UIImage? {
    if let cached = cache[stage] { return cached }
    let images = parts(for: stage).compactMap {
      UIImage(named: $0, in: .module, compatibleWith: nil)
    }
    guard let first = images.first else { return nil }
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = first.scale
    let image = UIGraphicsImageRenderer(size: first.size, format: format).image { _ in
      for part in images {
        part.draw(in: CGRect(origin: .zero, size: first.size))
      }
    }
    cache[stage] = image
    return image
  }
}
