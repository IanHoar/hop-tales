import SwiftUI

public struct Star: Shape {
  public var points = 5
  public var innerRatio: CGFloat = 0.42

  public init(points: Int = 5, innerRatio: CGFloat = 0.42) {
    self.points = points
    self.innerRatio = innerRatio
  }

  public func path(in rect: CGRect) -> Path {
    let centre = CGPoint(x: rect.midX, y: rect.midY)
    let outer = min(rect.width, rect.height) / 2
    let inner = outer * innerRatio
    var path = Path()
    for step in 0..<(points * 2) {
      let radius = step.isMultiple(of: 2) ? outer : inner
      let angle = -CGFloat.pi / 2 + CGFloat(step) * .pi / CGFloat(points)
      let point = CGPoint(
        x: centre.x + radius * cos(angle),
        y: centre.y + radius * sin(angle)
      )
      if step == 0 {
        path.move(to: point)
      } else {
        path.addLine(to: point)
      }
    }
    path.closeSubpath()
    return path
  }
}
