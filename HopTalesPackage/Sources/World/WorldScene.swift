import DesignSystem
import SpriteKit

public final class WorldScene: SKScene {
  public private(set) var progress: Double = 0
  public private(set) var stage: WorldStage = .meadow
  let farLayer = SKNode()
  let midLayer = SKNode()
  let nearLayer = SKNode()
  let actorLayer = SKNode()

  override public func didMove(to view: SKView) {
    super.didMove(to: view)
    scaleMode = .resizeFill
    backgroundColor = .clear
    for layer in [farLayer, midLayer, nearLayer, actorLayer] {
      addChild(layer)
    }
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
      let move = SKAction.moveTo(x: x, duration: 0.6)
      move.timingFunction = WorldScene.easeOutExpo
      layer.run(move)
    }
  }

  public func setStage(_ stage: WorldStage, animated: Bool = true) {
    self.stage = stage
  }

  static let easeOutExpo: (Float) -> Float = { t in
    t >= 1 ? 1 : 1 - pow(2, -10 * t)
  }
}
