import SpriteKit
import UIKit

public final class FoxNode: SKNode, Companion {
  static let canvas = CGRect(x: -58, y: -62, width: 106, height: 78)
  static let renderScale: CGFloat = 3
  static let jumpHeight: CGFloat = 18
  static let jumpTime: TimeInterval = 0.42
  static let landTime: TimeInterval = 0.14
  static let landSquash: CGFloat = 0.08
  static let strideAngle: CGFloat = 0.32
  static let strideLength: CGFloat = 30
  static let trotBounce: CGFloat = 1.6
  static let fullTrotSpeed: CGFloat = 220
  static let gaitEase: CGFloat = 0.12
  static let breathPeriod: CGFloat = 1.8
  static let swishPeriod: CGFloat = 1.4
  static let body = UIColor(red: 0.93, green: 0.56, blue: 0.31, alpha: 1)
  static let cream = UIColor(red: 1, green: 0.953, blue: 0.902, alpha: 1)
  static let ink = UIColor(red: 0.18, green: 0.165, blue: 0.231, alpha: 1)

  let shadow: SKSpriteNode
  let figure = SKNode()
  let tail: SKSpriteNode
  let torso: SKSpriteNode
  let head: SKSpriteNode
  let backLegs: [SKSpriteNode]
  let frontLegs: [SKSpriteNode]
  let headRest: CGPoint
  private var clock: TimeInterval = 0
  private var sinceJump: TimeInterval = .infinity
  private var gait: CGFloat = 0
  private var gaitPhase: CGFloat = 0

  override public init() {
    shadow = Self.part(pivot: CGPoint(x: 2, y: 4), draw: Self.drawShadow)
    tail = Self.part(pivot: CGPoint(x: -18, y: -22), draw: Self.drawTail)
    torso = Self.part(pivot: CGPoint(x: -2, y: -6), draw: Self.drawTorso)
    head = Self.part(pivot: CGPoint(x: 14, y: -22), draw: Self.drawHead)
    backLegs = [Self.farRearLeg, Self.nearRearLeg].map(Self.leg)
    frontLegs = [Self.farFrontLeg, Self.nearFrontLeg].map(Self.leg)
    headRest = head.position
    super.init()
    addChild(shadow)
    addChild(figure)
    let far = [backLegs[0], frontLegs[0]]
    let near = [backLegs[1], frontLegs[1]]
    for part in [tail] + far + near + [torso, head] {
      figure.addChild(part)
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
    torso.yScale = 1 + 0.025 * breath
    head.position = headRest + CGVector(dx: 0, dy: 0.6 * breath + 1.2 * gait * cos(2 * gaitPhase))
    tail.zRotation = 0.08 * sin(2 * .pi * clock / Self.swishPeriod) + 0.1 * gait * sin(gaitPhase)

    for (index, leg) in (backLegs + frontLegs).enumerated() {
      let diagonal = index == 0 || index == 3
      leg.zRotation = gait * Self.strideAngle * sin(gaitPhase + (diagonal ? 0 : .pi))
    }

    let bounce = gait * Self.trotBounce * abs(sin(gaitPhase))
    let jump = Self.jumpProgress(sinceJump)
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

  static func part(pivot: CGPoint, draw: @escaping (CGContext) -> Void) -> SKSpriteNode {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = renderScale
    let image = UIGraphicsImageRenderer(size: canvas.size, format: format).image { context in
      context.cgContext.translateBy(x: -canvas.minX, y: -canvas.minY)
      draw(context.cgContext)
    }
    let sprite = SKSpriteNode(texture: SKTexture(image: image), size: canvas.size)
    sprite.anchorPoint = CGPoint(
      x: (pivot.x - canvas.minX) / canvas.width,
      y: (canvas.maxY - pivot.y) / canvas.height
    )
    sprite.position = CGPoint(x: pivot.x, y: -pivot.y)
    return sprite
  }
}

extension CGPoint {
  static func + (point: CGPoint, offset: CGVector) -> CGPoint {
    CGPoint(x: point.x + offset.dx, y: point.y + offset.dy)
  }
}
