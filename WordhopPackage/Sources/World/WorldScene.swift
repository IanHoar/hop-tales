import DesignSystem
import SpriteKit

/// The parallax world behind the reading surface (`HANDOFF.md` §6).
///
/// One continuous world, 2340 × 844 pt, six phone-widths long; every screen is a crop of it. The
/// layers are painted once in neutral daylight — stages apply a colour grade plus additive light
/// sprites on top.
///
/// TODO(milestone-2): layer textures, fox actor, pollen.
/// TODO(milestone-3): sky crossfade, grades, light sprites, dragon bob/flap/fire.
public final class WorldScene: SKScene {
  /// World progress in near-layer points, 0 → 1950.
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

  /// Advances the world. One recognised word is one `Story.wordStep`.
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

  /// Crossfades the sky and lerps the colour grades. The near layer must not take the dusk hue
  /// shift — it turns the purple dragon green.
  public func setStage(_ stage: WorldStage, animated: Bool = true) {
    self.stage = stage
  }

  /// easeOutExpo — `cubic-bezier(0.16, 1, 0.3, 1)`.
  static let easeOutExpo: (Float) -> Float = { t in
    t >= 1 ? 1 : 1 - pow(2, -10 * t)
  }
}
