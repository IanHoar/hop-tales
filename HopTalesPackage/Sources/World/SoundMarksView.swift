import Content
import DesignSystem
import SwiftUI

public struct SoundMarksView: View {
  let word: String
  let size: CGFloat
  let color: Color

  public init(word: String, size: CGFloat, color: Color) {
    self.word = word
    self.size = size
    self.color = color
  }

  public static func height(for size: CGFloat) -> CGFloat { size * 0.3 }

  public var body: some View {
    if let marks = Phonics.shared.soundMarks(for: word) {
      let edges = (0...word.count).map { Typography.width(of: String(word.prefix($0)), size: size) }
      Canvas { context, _ in
        for mark in marks { draw(mark, edges: edges, in: &context) }
      }
      .frame(width: edges.last ?? 0, height: Self.height(for: size))
      .accessibilityHidden(true)
    }
  }

  private func draw(_ mark: SoundMark, edges: [CGFloat], in context: inout GraphicsContext) {
    let y = size * 0.08
    let centre = { (index: Int) in (edges[index] + edges[index + 1]) / 2 }
    switch mark.kind {
    case .button:
      let radius = size * 0.065
      let x = centre(mark.start)
      let dot = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
      context.fill(Path(ellipseIn: dot), with: .color(color))
    case .bar:
      let inset = size * 0.07
      let rect = CGRect(
        x: edges[mark.start] + inset, y: y - size * 0.04,
        width: max(size * 0.1, edges[mark.end] - edges[mark.start] - inset * 2), height: size * 0.08
      )
      context.fill(Path(roundedRect: rect, cornerRadius: size * 0.04), with: .color(color))
    case .split:
      var path = Path()
      let from = CGPoint(x: centre(mark.start), y: y)
      let to = CGPoint(x: centre(mark.end - 1), y: y)
      path.move(to: from)
      path.addQuadCurve(
        to: to, control: CGPoint(x: (from.x + to.x) / 2, y: y + size * 0.3)
      )
      let stroke = StrokeStyle(lineWidth: size * 0.06, lineCap: .round)
      context.stroke(path, with: .color(color), style: stroke)
    }
  }
}

public struct SoundMarksExamples: View {
  public static let words = ["cat", "ship", "lake"]
  let size: CGFloat

  public init(size: CGFloat = 30) {
    self.size = size
  }

  public var body: some View {
    HStack(spacing: size * 0.9) {
      ForEach(Self.words, id: \.self) { word in
        VStack(spacing: size * 0.08) {
          Text(word)
            .font(Typography.word(size))
            .foregroundStyle(Paper.ink)
            .fixedSize()
          SoundMarksView(word: word, size: size, color: Paper.ink.opacity(0.8))
        }
      }
    }
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Examples: cat, ship and lake, with a dot under each sound.")
  }
}
