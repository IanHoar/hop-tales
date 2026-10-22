import SwiftUI

public struct PadlockGlyph: View {
  let color: Color
  let hole: Color

  public init(color: Color = Paper.ink, hole: Color = Paper.paper) {
    self.color = color
    self.hole = hole
  }

  public var body: some View {
    Canvas { context, size in
      let unit = size.width / 24
      var shackle = Path()
      shackle.move(to: CGPoint(x: 8 * unit, y: 11 * unit))
      shackle.addLine(to: CGPoint(x: 8 * unit, y: 8 * unit))
      shackle.addArc(
        center: CGPoint(x: 12 * unit, y: 8 * unit),
        radius: 4 * unit,
        startAngle: .degrees(180),
        endAngle: .degrees(0),
        clockwise: false
      )
      shackle.addLine(to: CGPoint(x: 16 * unit, y: 11 * unit))
      context.stroke(
        shackle,
        with: .color(color),
        style: StrokeStyle(lineWidth: 2.4 * unit, lineCap: .round)
      )
      let body = Path(
        roundedRect: CGRect(x: 5 * unit, y: 10.5 * unit, width: 14 * unit, height: 10 * unit),
        cornerRadius: 2.5 * unit
      )
      context.fill(body, with: .color(color))
      let keyhole = Path(
        ellipseIn: CGRect(x: 10.4 * unit, y: 13 * unit, width: 3.2 * unit, height: 3.2 * unit)
      )
      context.fill(keyhole, with: .color(hole))
      let slot = Path(
        roundedRect: CGRect(x: 11.3 * unit, y: 14.6 * unit, width: 1.4 * unit, height: 3.4 * unit),
        cornerRadius: 0.7 * unit
      )
      context.fill(slot, with: .color(hole))
    }
    .aspectRatio(1, contentMode: .fit)
    .accessibilityHidden(true)
  }
}

public struct PadlockSticker: View {
  let size: CGFloat

  public init(size: CGFloat = 30) {
    self.size = size
  }

  public var body: some View {
    PadlockGlyph(hole: Paper.wash)
      .padding(size * 0.2)
      .frame(width: size, height: size)
      .background(Paper.wash, in: Circle())
      .overlay(Circle().strokeBorder(Paper.rim, lineWidth: max(2, size * 0.09)))
      .compositingGroup()
      .shadow(color: Paper.shadow, radius: size * 0.1, y: size * 0.07)
      .rotationEffect(.degrees(-8))
      .accessibilityHidden(true)
  }
}
