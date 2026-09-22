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
    backLegs = [-14, 8].map { x in
      Self.part(pivot: CGPoint(x: x + 3.5, y: -12)) {
        Self.drawLeg($0, x: x, top: -14, colour: 0xB85F32)
      }
    }
    frontLegs = [(-6.0, -12.0), (14.0, -14.0)].map { x, top in
      Self.part(pivot: CGPoint(x: x + 3.5, y: top + 2)) {
        Self.drawLeg($0, x: x, top: top, colour: 0xEE8F50)
      }
    }
    headRest = head.position
    super.init()
    addChild(shadow)
    addChild(figure)
    for part in [tail] + backLegs + [torso] + frontLegs + [head] {
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

  static func colour(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    UIColor(
      red: CGFloat((hex >> 16) & 0xFF) / 255,
      green: CGFloat((hex >> 8) & 0xFF) / 255,
      blue: CGFloat(hex & 0xFF) / 255,
      alpha: alpha
    ).cgColor
  }

  static func fill(
    _ context: CGContext,
    _ path: CGPath,
    gradient stops: [(CGFloat, UInt32)],
    centre: CGPoint,
    radius: CGFloat
  ) {
    guard let gradient = CGGradient(
      colorsSpace: CGColorSpaceCreateDeviceRGB(),
      colors: stops.map { colour($0.1) } as CFArray,
      locations: stops.map(\.0)
    ) else { return }
    context.saveGState()
    context.addPath(path)
    context.clip()
    context.drawRadialGradient(
      gradient,
      startCenter: centre,
      startRadius: 0,
      endCenter: centre,
      endRadius: radius,
      options: .drawsAfterEndLocation
    )
    context.restoreGState()
  }

  static func fill(_ context: CGContext, _ path: CGPath, _ hex: UInt32, alpha: CGFloat = 1) {
    context.addPath(path)
    context.setFillColor(colour(hex, alpha: alpha))
    context.fillPath()
  }

  static let bodyStops: [(CGFloat, UInt32)] = [(0, 0xFFB070), (0.6, 0xEE8F50), (1, 0xC96A34)]

  static func triangle(_ corners: CGFloat...) -> CGPath {
    let path = CGMutablePath()
    path.addLines(between: stride(from: 0, to: corners.count - 1, by: 2).map {
      CGPoint(x: corners[$0], y: corners[$0 + 1])
    })
    path.closeSubpath()
    return path
  }

  static func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> CGPath {
    CGPath(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2), transform: nil)
  }

  static func capsule(_ rect: CGRect) -> CGPath {
    let radius = min(rect.width, rect.height) / 2
    return CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
  }

  static func drawShadow(_ context: CGContext) {
    context.setShadow(offset: .zero, blur: 3, color: colour(0x1E3A20, alpha: 0.28))
    fill(context, ellipse(2, 4, 32, 7), 0x1E3A20, alpha: 0.28)
  }

  static func drawTail(_ context: CGContext) {
    let tail = CGMutablePath()
    tail.move(to: CGPoint(x: -20, y: -20))
    tail.addCurve(
      to: CGPoint(x: -46, y: -54),
      control1: CGPoint(x: -36, y: -26),
      control2: CGPoint(x: -50, y: -38)
    )
    tail.addCurve(
      to: CGPoint(x: -16, y: -26),
      control1: CGPoint(x: -34, y: -44),
      control2: CGPoint(x: -26, y: -34)
    )
    tail.closeSubpath()
    fill(context, tail, gradient: bodyStops, centre: CGPoint(x: -37, y: -44), radius: 30)

    let tip = CGMutablePath()
    tip.move(to: CGPoint(x: -46, y: -54))
    tip.addCurve(
      to: CGPoint(x: -42, y: -38),
      control1: CGPoint(x: -50, y: -48),
      control2: CGPoint(x: -48, y: -40)
    )
    tip.addCurve(
      to: CGPoint(x: -46, y: -54),
      control1: CGPoint(x: -44, y: -44),
      control2: CGPoint(x: -44, y: -50)
    )
    tip.closeSubpath()
    fill(context, tip, 0xFFF3E6)
  }

  static func drawLeg(_ context: CGContext, x: CGFloat, top: CGFloat, colour hex: UInt32) {
    let height = -top + 2
    fill(context, capsule(CGRect(x: x, y: top, width: 7, height: height)), hex)
    fill(context, capsule(CGRect(x: x, y: 0, width: 7, height: 3)), 0x3A2417)
  }

  static func drawTorso(_ context: CGContext) {
    let body = CGMutablePath()
    body.move(to: CGPoint(x: -20, y: -18))
    body.addCurve(
      to: CGPoint(x: 8, y: -32),
      control1: CGPoint(x: -18, y: -32),
      control2: CGPoint(x: -4, y: -36)
    )
    body.addCurve(
      to: CGPoint(x: 14, y: -10),
      control1: CGPoint(x: 16, y: -28),
      control2: CGPoint(x: 18, y: -18)
    )
    body.addCurve(
      to: CGPoint(x: -20, y: -18),
      control1: CGPoint(x: 6, y: -4),
      control2: CGPoint(x: -14, y: -4)
    )
    body.closeSubpath()
    fill(context, body, gradient: bodyStops, centre: CGPoint(x: -5, y: -26), radius: 30)
    fill(context, ellipse(0, -14, 10, 6), 0xFFF3E6)
  }

  static func drawHead(_ context: CGContext) {
    let skull = ellipse(18, -30, 11.5, 11.5)
    let headStops: [(CGFloat, UInt32)] = [(0, 0xFFBE82), (1, 0xE4823F)]
    fill(context, skull, gradient: headStops, centre: CGPoint(x: 16.5, y: -33), radius: 17)
    fill(context, triangle(9, -37, 11, -52, 20, -40), 0xD9743B)
    fill(context, triangle(11, -39, 12, -47, 17, -41), 0xFFD3A5)
    fill(context, triangle(22, -38, 28, -51, 31, -37), 0xD9743B)
    fill(context, triangle(24, -40, 28, -47, 29, -39), 0xFFD3A5)
    fill(context, ellipse(26, -26, 6.5, 5), 0xFFF3E6)
    fill(context, ellipse(30.5, -27, 2, 2), 0x2E2A3B)
    fill(context, ellipse(20, -32, 2.5, 2.5), 0x2E2A3B)
    fill(context, ellipse(21, -33, 0.9, 0.9), 0xFFFFFF)

    let brow = CGMutablePath()
    brow.move(to: CGPoint(x: 12, y: -40))
    brow.addCurve(
      to: CGPoint(x: 26, y: -41),
      control1: CGPoint(x: 16, y: -44),
      control2: CGPoint(x: 22, y: -44)
    )
    context.addPath(brow)
    context.setStrokeColor(colour(0xFFD3A5, alpha: 0.8))
    context.setLineWidth(1.5)
    context.setLineCap(.round)
    context.strokePath()
  }
}

extension CGPoint {
  static func + (point: CGPoint, offset: CGVector) -> CGPoint {
    CGPoint(x: point.x + offset.dx, y: point.y + offset.dy)
  }
}
