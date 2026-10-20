import SwiftUI

public struct Deckle: Shape {
  let seed: Int
  let jitter: CGFloat
  let step: CGFloat

  public init(seed: Int = 1, jitter: CGFloat = 2.4, step: CGFloat = 9) {
    self.seed = seed
    self.jitter = jitter
    self.step = step
  }

  public func path(in rect: CGRect) -> Path {
    var random = Scatter(seed: seed)
    var path = Path()
    let topLeft = CGPoint(x: rect.minX, y: rect.minY)
    let topRight = CGPoint(x: rect.maxX, y: rect.minY)
    let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
    let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
    let corners = [
      (topLeft, topRight, CGVector(dx: 0, dy: 1)),
      (topRight, bottomRight, CGVector(dx: -1, dy: 0)),
      (bottomRight, bottomLeft, CGVector(dx: 0, dy: -1)),
      (bottomLeft, topLeft, CGVector(dx: 1, dy: 0))
    ]
    for (start, end, inward) in corners {
      let length = hypot(end.x - start.x, end.y - start.y)
      let count = max(2, Int(length / step))
      for index in 0..<count {
        let fraction = CGFloat(index) / CGFloat(count)
        let bite = random.next() * jitter
        let point = CGPoint(
          x: start.x + (end.x - start.x) * fraction + inward.dx * bite,
          y: start.y + (end.y - start.y) * fraction + inward.dy * bite
        )
        if path.isEmpty { path.move(to: point) } else { path.addLine(to: point) }
      }
    }
    path.closeSubpath()
    return path
  }
}

private struct Scatter {
  var state: UInt64

  init(seed: Int) {
    state = UInt64(bitPattern: Int64(seed)) &* 0x9E37_79B9_7F4A_7C15 | 1
  }

  mutating func next() -> CGFloat {
    state ^= state << 13
    state ^= state >> 7
    state ^= state << 17
    return CGFloat(state % 10_000) / 10_000
  }
}

public struct PaperLabel<Content: View>: View {
  let seed: Int
  let content: Content

  public init(seed: Int = 1, @ViewBuilder content: () -> Content) {
    self.seed = seed
    self.content = content()
  }

  public var body: some View {
    content
      .background(Paper.paper, in: Deckle(seed: seed))
      .compositingGroup()
      .shadow(color: Paper.shadow, radius: 3.5, y: 4)
  }
}

#Preview {
  VStack(spacing: 30) {
    PaperLabel {
      Text("Hop Tales")
        .font(Typography.display(46))
        .foregroundStyle(Paper.ink)
        .padding(.horizontal, 28)
        .padding(.vertical, 14)
    }
    .rotationEffect(.degrees(-2))
    PaperLabel(seed: 4) {
      Text("Good morning, Robin!")
        .font(Typography.display(21))
        .foregroundStyle(Paper.ink)
        .padding(.horizontal, 18)
        .padding(.vertical, 9)
    }
    .rotationEffect(.degrees(-3))
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(Paper.sage)
}
