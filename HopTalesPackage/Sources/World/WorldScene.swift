import DesignSystem
import SpriteKit
import UIKit

public final class WorldScene: SKScene {
  public private(set) var progress: Double = 0
  public private(set) var stage: WorldStage = .meadow

  public static let crossfade: TimeInterval = 0.6
  public static let scrollDuration: TimeInterval = 0.6
  static let scrollKey = "scroll"
  static let artName = "art"

  let world = SKNode()
  let skyNode = SKSpriteNode()
  let farLayer = SKNode()
  let midLayer = SKNode()
  let nearLayer = SKNode()
  let actorLayer = SKNode()
  let companionLayer = SKNode()
  let particleLayer = SKNode()
  let knight = KnightNode()
  let dragon = DragonNode()
  let particles = AmbientParticles.emitter()
  static let companionHome = CGPoint(x: 118, y: WorldMetrics.size.height - 441)

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
      world.addChild(particleLayer)
      mountParticles()
      world.addChild(companionLayer)
      mountCompanion()
    }
    layOut()
  }

  override public func didChangeSize(_ oldSize: CGSize) {
    super.didChangeSize(oldSize)
    layOut()
  }

  private var artLayers: [(WorldArt.Layer, SKNode)] {
    [(.far, farLayer), (.mid, midLayer), (.near, nearLayer)]
  }

  private func mountArt() {
    let tone = WorldArt.Tone(stage: stage)
    skyNode.anchorPoint = .zero
    skyNode.zPosition = -40
    skyNode.size = WorldMetrics.size
    skyNode.texture = WorldArt(.sky, tone).texture().map(SKTexture.init(image:))

    for (depth, pair) in artLayers.enumerated() {
      let (art, layer) = pair
      layer.zPosition = CGFloat(depth - 3) * 10
      let sprite = SKSpriteNode()
      sprite.name = Self.artName
      sprite.anchorPoint = .zero
      sprite.size = WorldMetrics.size
      sprite.texture = WorldArt(art, tone).texture().map(SKTexture.init(image:))
      layer.addChild(sprite)
    }
    actorLayer.zPosition = 0
    actorLayer.addChild(knight)
    actorLayer.addChild(dragon)
    grade(for: stage)
  }

  private func layOut() {
    guard size.height > 0, size != builtSize else { return }
    builtSize = size

    world.setScale(size.height / WorldMetrics.size.height)
    layOutParticles()
  }

  override public func update(_ currentTime: TimeInterval) {
    let elapsed = lastFrame.map { min(currentTime - $0, 1.0 / 20) } ?? 0
    lastFrame = currentTime
    let travelled = lastNearX - nearLayer.position.x
    lastNearX = nearLayer.position.x
    companion.update(elapsed: elapsed, travelled: travelled)
    knight.update(elapsed: elapsed, foxAt: Self.companionHome.x - nearLayer.position.x)
    dragon.update(elapsed: elapsed)
  }

  private func mountParticles() {
    particles.targetNode = actorLayer
    particleLayer.zPosition = 2
    particleLayer.addChild(particles)
    tintParticles()
  }

  private func layOutParticles() {
    let span = size.width / world.xScale * AmbientParticles.coverage
    let band = AmbientParticles.band
    particles.position = CGPoint(
      x: span / 2,
      y: WorldMetrics.size.height - (band.lowerBound + band.upperBound) / 2
    )
    particles.particlePositionRange = CGVector(
      dx: span,
      dy: band.upperBound - band.lowerBound
    )
    particles.resetSimulation()
    particles.advanceSimulationTime(TimeInterval(AmbientParticles.lifetime))
  }

  private func tintParticles() {
    guard let colour = AmbientParticles.colour(for: stage) else {
      particles.particleBirthRate = 0
      return
    }
    particles.particleColor = colour
    particles.particleBirthRate = AmbientParticles.birthRate
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

  public func roar() {
    dragon.roar()
  }

  private func grade(for stage: WorldStage) {
    let dusk = stage == .dragon
    for node in [knight.body, dragon.body, dragon.wing] {
      node.color = UIColor(red: 0.8, green: 0.78, blue: 0.88, alpha: 1)
      node.colorBlendFactor = dusk ? 0.2 : 0
    }
  }

  public func setStage(_ stage: WorldStage, animated: Bool = true) {
    self.stage = stage
    tintParticles()
    grade(for: stage)
    let tone = WorldArt.Tone(stage: stage)
    crossfade(skyNode, in: world, to: WorldArt(.sky, tone), animated: animated)
    for (art, layer) in artLayers {
      guard let sprite = layer.childNode(withName: Self.artName) as? SKSpriteNode else { continue }
      crossfade(sprite, in: layer, to: WorldArt(art, tone), animated: animated)
    }
  }

  private func crossfade(
    _ sprite: SKSpriteNode,
    in parent: SKNode,
    to art: WorldArt,
    animated: Bool
  ) {
    guard let image = art.texture() else { return }
    let texture = SKTexture(image: image)
    guard animated, sprite.parent != nil else {
      sprite.texture = texture
      return
    }
    let incoming = SKSpriteNode(texture: texture)
    incoming.anchorPoint = .zero
    incoming.size = sprite.size
    incoming.position = sprite.position
    incoming.zPosition = sprite.zPosition + 1
    incoming.alpha = 0
    parent.addChild(incoming)
    let fade = SKAction.sequence([.fadeIn(withDuration: Self.crossfade), .removeFromParent()])
    incoming.run(fade) { [weak sprite] in
      sprite?.texture = texture
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
