import DesignSystem
import SpriteKit
import UIKit

public final class WorldScene: SKScene {
  public private(set) var progress: Double = 0
  public private(set) var stage: WorldStage = .meadow

  public static let textureWidth: CGFloat = 2340
  public static let crossfade: TimeInterval = 0.6
  public static let scrollDuration: TimeInterval = 0.6

  let world = SKNode()
  let skyNode = SKSpriteNode()
  let farLayer = SKNode()
  let midLayer = SKNode()
  let nearLayer = SKNode()
  let actorLayer = SKNode()

  private var builtSize: CGSize = .zero

  override public func didMove(to view: SKView) {
    super.didMove(to: view)
    scaleMode = .resizeFill
    anchorPoint = .zero
    backgroundColor = .clear
    if world.parent == nil {
      addChild(world)
      world.addChild(skyNode)
      for layer in [farLayer, midLayer, nearLayer, actorLayer] {
        world.addChild(layer)
      }
      mountArt()
    }
    layOut()
  }

  override public func didChangeSize(_ oldSize: CGSize) {
    super.didChangeSize(oldSize)
    layOut()
  }

  private func mountArt() {
    skyNode.anchorPoint = .zero
    skyNode.zPosition = -40
    skyNode.texture = WorldArt.sky(stage).map(SKTexture.init(image:))

    let parallax: [(WorldArt, SKNode)] = [
      (.layerFar, farLayer),
      (.layerMid, midLayer),
      (.layerNear, nearLayer)
    ]
    for (depth, pair) in parallax.enumerated() {
      let (art, layer) = pair
      layer.zPosition = CGFloat(depth - 3) * 10
      guard let image = art.image(width: Self.textureWidth) else { continue }
      let sprite = SKSpriteNode(texture: SKTexture(image: image))
      sprite.anchorPoint = .zero
      sprite.size = WorldMetrics.size
      layer.addChild(sprite)
    }
    actorLayer.zPosition = 0
  }

  private func layOut() {
    guard size.height > 0, size != builtSize else { return }
    builtSize = size

    let scale = size.height / WorldMetrics.size.height
    world.setScale(scale)

    skyNode.size = CGSize(width: size.width / scale, height: WorldMetrics.size.height)
  }

  public func setProgress(_ progress: Double, animated: Bool = true) {
    self.progress = progress
    let stage = WorldStage(progress: progress)
    if stage != self.stage { setStage(stage, animated: animated) }

    for (layer, speed) in [(farLayer, 0.3), (midLayer, 0.6), (nearLayer, 1.0), (actorLayer, 1.0)] {
      let x = -speed * progress
      guard animated else {
        layer.position.x = x
        continue
      }
      let move = SKAction.moveTo(x: x, duration: Self.scrollDuration)
      move.timingFunction = WorldScene.easeOutExpo
      layer.run(move)
    }
  }

  public func setStage(_ stage: WorldStage, animated: Bool = true) {
    self.stage = stage
    guard let sky = WorldArt.sky(stage) else { return }
    let texture = SKTexture(image: sky)
    guard animated else {
      skyNode.texture = texture
      return
    }
    let incoming = SKSpriteNode(texture: texture)
    incoming.anchorPoint = .zero
    incoming.size = skyNode.size
    incoming.zPosition = skyNode.zPosition + 1
    incoming.alpha = 0
    world.addChild(incoming)
    let crossfade = SKAction.sequence([
      SKAction.fadeIn(withDuration: Self.crossfade),
      SKAction.removeFromParent()
    ])
    incoming.run(crossfade) { [weak self] in
      self?.skyNode.texture = texture
    }
  }

  static let easeOutExpo: (Float) -> Float = { t in
    t >= 1 ? 1 : 1 - pow(2, -10 * t)
  }
}

public struct LayerOffsets: Equatable, Sendable {
  public var far: Double
  public var mid: Double
  public var near: Double

  public init(progress: Double) {
    far = -0.3 * progress
    mid = -0.6 * progress
    near = -1.0 * progress
  }
}
