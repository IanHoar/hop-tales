import DesignSystem
import SwiftUI

struct Star: Shape {
  var points = 5
  var innerRatio: CGFloat = 0.42

  func path(in rect: CGRect) -> Path {
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

struct Sparkles: View {
  let geometry: ReadingGeometry
  var isAnimating = true

  static let duration: TimeInterval = 0.5
  static let delays: [TimeInterval] = [0, 0.08, 0.16]
  static let offsets: [CGSize] = [
    CGSize(width: -54, height: -30),
    CGSize(width: -74, height: 4),
    CGSize(width: -28, height: -52)
  ]
  static let sizes: [CGFloat] = [13, 10, 8]

  var body: some View {
    ZStack {
      ForEach(Array(Self.delays.enumerated()), id: \.offset) { index, delay in
        Sparkle(
          size: geometry.scaled(Self.sizes[index]),
          delay: delay,
          isAnimating: isAnimating
        )
        .offset(
          x: geometry.scaled(Self.offsets[index].width),
          y: geometry.scaled(Self.offsets[index].height)
        )
      }
    }
  }

  private struct Sparkle: View {
    let size: CGFloat
    let delay: TimeInterval
    let isAnimating: Bool

    @State private var scale: CGFloat = 0

    var body: some View {
      Star()
        .fill(Palette.amber)
        .frame(width: size, height: size)
        .scaleEffect(scale)
        .task {
          guard isAnimating else { return }
          try? await Task.sleep(for: .seconds(delay))
          withAnimation(.easeOut(duration: Sparkles.duration / 2)) { scale = 1 }
          try? await Task.sleep(for: .seconds(Sparkles.duration / 2))
          withAnimation(.easeIn(duration: Sparkles.duration / 2)) { scale = 0 }
        }
    }
  }
}
