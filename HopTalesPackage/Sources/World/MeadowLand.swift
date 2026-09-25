import Content
import SpriteKit

struct PropPlacement: Equatable {
  let asset: String
  let x: CGFloat
  let depth: CGFloat
}

enum MeadowProps {
  static let assets = [
    "prop-bush", "prop-fence", "prop-flowers", "prop-mushrooms", "prop-oak", "prop-signpost"
  ]
  static let segmentWidth: CGFloat = 900

  static func placements(inSegment index: Int) -> [PropPlacement] {
    var random = SeededRandom(seed: index &* 7919)
    let count = Int.random(in: 0...2, using: &random)
    return (0..<count).map { slot in
      let span = segmentWidth / CGFloat(max(count, 1))
      return PropPlacement(
        asset: assets.randomElement(using: &random) ?? assets[0],
        x: CGFloat(slot) * span + CGFloat.random(in: 0.15...0.85, using: &random) * span,
        depth: CGFloat.random(in: 0...1, using: &random)
      )
    }
  }
}

final class TiledLayer: SKNode {
  let layer: MeadowLayer
  private(set) var tiles: [SKSpriteNode] = []

  init(_ layer: MeadowLayer) {
    self.layer = layer
    super.init()
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  func layout(_ layout: MeadowLayout, world: Friend, tint: UIColor) {
    let count = layout.tileCount(of: layer)
    let texture = MeadowArt.texture(layer.asset(in: world))
    for tile in tiles where tile.texture != texture {
      tile.texture = texture
    }
    while tiles.count < count {
      let tile = SKSpriteNode(texture: texture)
      tile.anchorPoint = CGPoint(x: 0, y: 1)
      tile.color = tint
      tile.colorBlendFactor = 1
      tiles.append(tile)
      addChild(tile)
    }
    for tile in tiles {
      tile.size = layout.tileSize(of: layer)
      tile.position.y = layout.size.height - layout.top(of: layer)
    }
  }

  func scroll(_ layout: MeadowLayout, progress: Double) {
    let offset = layout.offset(of: layer, progress: progress)
    let width = layout.tileSize(of: layer).width
    for (index, tile) in tiles.enumerated() {
      tile.position.x = offset + CGFloat(index) * width
    }
  }

  func tint(_ color: UIColor, duration: TimeInterval) {
    for tile in tiles {
      tile.removeAction(forKey: "tint")
      if duration > 0 {
        tile.run(.colorize(with: color, colorBlendFactor: 1, duration: duration), withKey: "tint")
      } else {
        tile.color = color
      }
    }
  }
}

final class PropLayer: SKNode {
  private var segments: [Int: [SKSpriteNode]] = [:]
  private var tint = UIColor.white

  func scroll(_ layout: MeadowLayout, progress: Double) {
    let width = MeadowProps.segmentWidth * layout.scale
    guard width > 0 else { return }
    let scroll = CGFloat(progress)
    let first = Int(floor(scroll / width)) - 1
    let last = Int(floor((scroll + layout.size.width) / width)) + 1
    for index in segments.keys where index < first || index > last {
      segments.removeValue(forKey: index)?.forEach { $0.removeFromParent() }
    }
    for index in first...last where segments[index] == nil {
      segments[index] = MeadowProps.placements(inSegment: index).map { place($0, layout: layout) }
    }
    position.x = -scroll
    for (index, nodes) in segments {
      let placements = MeadowProps.placements(inSegment: index)
      for (node, placement) in zip(nodes, placements) {
        node.position.x = CGFloat(index) * width + placement.x * layout.scale
      }
    }
  }

  private func place(_ placement: PropPlacement, layout: MeadowLayout) -> SKSpriteNode {
    let node = SKSpriteNode(texture: MeadowArt.texture(placement.asset))
    let scale = layout.scale * (0.62 + 0.3 * placement.depth)
    node.size = CGSize(width: node.size.width * scale, height: node.size.height * scale)
    node.anchorPoint = CGPoint(x: 0.5, y: 0.04)
    let ground = layout.top(of: .near) + (300 + 90 * placement.depth) * layout.scale
    node.position.y = layout.size.height - ground
    node.zPosition = placement.depth
    node.color = tint
    node.colorBlendFactor = 1
    addChild(node)
    return node
  }

  func tint(_ color: UIColor, duration: TimeInterval) {
    tint = color
    for node in segments.values.flatMap(\.self) {
      node.removeAction(forKey: "tint")
      if duration > 0 {
        node.run(.colorize(with: color, colorBlendFactor: 1, duration: duration), withKey: "tint")
      } else {
        node.color = color
      }
    }
  }

  func reset() {
    segments.values.flatMap(\.self).forEach { $0.removeFromParent() }
    segments = [:]
  }
}
