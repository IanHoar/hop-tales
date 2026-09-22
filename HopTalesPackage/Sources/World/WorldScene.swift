import DesignSystem
import SpriteKit
import UIKit

public final class WorldScene: SKScene {
  public private(set) var progress: Double = 0
  public private(set) var stage: WorldStage = .meadow

  public static let textureWidth: CGFloat = 2340
  public static let crossfade: TimeInterval = 0.6
  public static let scrollDuration: TimeInterval = 0.6
  static let scrollKey = "scroll"

  let world = SKNode()
  let skyNode = SKSpriteNode()
  let farLayer = SKNode()
  let midLayer = SKNode()
  let nearLayer = SKNode()
  let actorLayer = SKNode()
  let companionLayer = SKNode()
  static let companionHome = CGPoint(x: 150, y: WorldMetrics.size.height - 436)

  public var companion: any Companion = FoxNode() {
    didSet {
      oldValue.removeFromParent()
      mountCompanion()
    }
  }

  private var builtSize: CGSize = .zero
  private var lastFrame: TimeInterval?
  private var lastNearX: CGFloat = 0

  override public init(size: CGSize) {
    super.init(size: size)
    scaleMode = .resizeFill
    anchorPoint = .zero
    backgroundColor = .clear
  }

  @available(*, unavailable)
  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override public func didMove(to view: SKView) {
    super.didMove(to: view)
    if world.parent == nil {
      addChild(world)
      world.addChild(skyNode)
      for layer in [farLayer, midLayer, nearLayer, actorLayer] {
        world.addChild(layer)
      }
      mountArt()
      world.addChild(companionLayer)
      mountCompanion()
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
    skyNode.size = WorldMetrics.size
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

    world.setScale(size.height / WorldMetrics.size.height)
  }

  override public func update(_ currentTime: TimeInterval) {
    let elapsed = lastFrame.map { min(currentTime - $0, 1.0 / 20) } ?? 0
    lastFrame = currentTime
    let travelled = lastNearX - nearLayer.position.x
    lastNearX = nearLayer.position.x
    companion.update(elapsed: elapsed, travelled: travelled)
  }

  private func mountCompanion() {
    companionLayer.zPosition = 5
    companion.position = Self.companionHome
    companionLayer.addChild(companion)
    companion.update(elapsed: 0, travelled: 0)
  }

  public func setProgress(_ progress: Double, animated: Bool = true) {
    if animated, progress > self.progress {
      companion.celebrate()
    }
    self.progress = progress
    let stage = WorldStage(progress: progress)
    if stage != self.stage { setStage(stage, animated: animated) }

    let offsets = LayerOffsets(progress: progress)
    let targets = [
      (farLayer, offsets.far),
      (midLayer, offsets.mid),
      (nearLayer, offsets.near),
      (actorLayer, offsets.near)
    ]
    for (layer, x) in targets {
      layer.removeAction(forKey: Self.scrollKey)
      guard animated else {
        layer.position.x = CGFloat(x)
        continue
      }
      let move = SKAction.moveTo(x: CGFloat(x), duration: Self.scrollDuration)
      move.timingFunction = Self.easeOutExpo
      layer.run(move, withKey: Self.scrollKey)
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
