import SpriteKit
import UIKit

public final class FoxNode: SKNode, Companion {
  static let scale: CGFloat = 0.62
  static let jumpHeight: CGFloat = 18
  static let jumpTime: TimeInterval = 0.42
  static let landTime: TimeInterval = 0.14
  static let landSquash: CGFloat = 0.08
  static let strideAngle: CGFloat = 0.31
  static let strideLength: CGFloat = 30
  static let trotBounce: CGFloat = 1.6
  static let fullTrotSpeed: CGFloat = 220
  static let gaitEase: CGFloat = 0.12
  static let breathPeriod: CGFloat = 1.8
  static let swishPeriod: CGFloat = 1.4

  let shadow: SKSpriteNode
  let figure = SKNode()
  let rig = SKNode()
  let tail: SKSpriteNode
  let torso: SKSpriteNode
  let head: SKSpriteNode
  let scarf: SKSpriteNode
  let wrap: SKSpriteNode
  let backLegs: [SKSpriteNode]
  let frontLegs: [SKSpriteNode]
  let headRest: CGPoint
  let idleFace: SKTexture?
  let happyFace: SKTexture?
  private var clock: TimeInterval = 0
  private var sinceJump: TimeInterval = .infinity
  private var gait: CGFloat = 0
  private var gaitPhase: CGFloat = 0

  override public init() {
    let rigging = Rigging.fox
    shadow = rigging.sprite("fox-shadow")
    tail = rigging.sprite("fox-tail")
    torso = rigging.sprite("fox-body")
    head = rigging.sprite("fox-head-idle")
    scarf = rigging.sprite("fox-scarf")
    wrap = rigging.sprite("fox-wrap")
    backLegs = [rigging.sprite("fox-leg-far-rear"), rigging.sprite("fox-leg-near-rear")]
    frontLegs = [rigging.sprite("fox-leg-far-front"), rigging.sprite("fox-leg-near-front")]
    idleFace = head.texture
    happyFace = rigging.texture("fox-head-happy")
    headRest = head.position
    super.init()
    shadow.setScale(Self.scale)
    addChild(shadow)
    addChild(figure)
    rig.setScale(Self.scale)
    figure.addChild(rig)
    let far = [backLegs[0], frontLegs[0]]
    let near = [backLegs[1], frontLegs[1]]
    for part in [tail] + far + [torso] + near + [scarf, head, wrap] {
      rig.addChild(part)
    }
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  public func celebrate() {
    sinceJump = 0
  }

  public func update(elapsed: TimeInterval, travelled: CGFloat) {
    clock += elapsed
    sinceJump += elapsed

    let speed = elapsed > 0 ? abs(travelled) / CGFloat(elapsed) : 0
    let target = min(speed / Self.fullTrotSpeed, 1)
    let blend = min(CGFloat(elapsed) / Self.gaitEase, 1)
    gait += (target - gait) * blend
    gaitPhase += abs(travelled) / Self.strideLength * 2 * .pi

    pose(clock: CGFloat(clock))
  }

  func pose(clock: CGFloat) {
    let breath = sin(2 * .pi * clock / Self.breathPeriod)
    torso.yScale = 1 + 0.02 * breath
    scarf.zRotation = 0.08 * gait * sin(2 * gaitPhase) + 0.05 * breath
    head.position = headRest + CGVector(dx: 0, dy: 0.6 * breath + 1.2 * gait * cos(2 * gaitPhase))
    tail.zRotation = 0.08 * sin(2 * .pi * clock / Self.swishPeriod) + 0.1 * gait * sin(gaitPhase)

    for (index, leg) in (backLegs + frontLegs).enumerated() {
      let diagonal = index == 0 || index == 3
      leg.zRotation = gait * Self.strideAngle * sin(gaitPhase + (diagonal ? 0 : .pi))
    }

    let bounce = gait * Self.trotBounce * abs(sin(gaitPhase))
    let jump = Self.jumpProgress(sinceJump)
    head.texture = jump.height > 0 || jump.squash > 0 ? happyFace : idleFace
    figure.position.y = bounce + Self.jumpHeight * jump.height
    figure.yScale = 1 - jump.squash
    figure.xScale = 1 + jump.squash * 0.6
    shadow.setScale(1 - 0.3 * jump.height)
    shadow.alpha = 1 - 0.4 * jump.height
  }

  static func jumpProgress(_ time: TimeInterval) -> (height: CGFloat, squash: CGFloat) {
    guard time >= 0 else { return (0, 0) }
    if time < jumpTime {
      let p = CGFloat(time / jumpTime)
      return (4 * p * (1 - p), 0)
    }
    let landing = time - jumpTime
    guard landing < landTime else { return (0, 0) }
    return (0, landSquash * CGFloat(sin(.pi * landing / landTime)))
  }

}

extension CGPoint {
  static func + (point: CGPoint, offset: CGVector) -> CGPoint {
    CGPoint(x: point.x + offset.dx, y: point.y + offset.dy)
  }
}
