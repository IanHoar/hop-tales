import SpriteKit
import UIKit

extension FoxNode {
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

  struct Leg {
    var x: CGFloat
    var top: CGFloat
    var colour: UInt32
  }

  static let farRearLeg = Leg(x: -17, top: -14, colour: 0xB85F32)
  static let nearRearLeg = Leg(x: -12, top: -12, colour: 0xEE8F50)
  static let farFrontLeg = Leg(x: 4, top: -14, colour: 0xB85F32)
  static let nearFrontLeg = Leg(x: 9, top: -11, colour: 0xEE8F50)

  static func leg(_ leg: Leg) -> SKSpriteNode {
    part(pivot: CGPoint(x: leg.x + 3.5, y: leg.top + 3)) {
      drawLeg($0, x: leg.x, top: leg.top, colour: leg.colour)
    }
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

  }
}
