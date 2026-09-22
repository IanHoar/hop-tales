import Content
import DesignSystem
import SwiftUI
import World

struct ProgressRail: View {
  let story: Story
  let sentenceIndex: Int
  let geometry: ReadingGeometry

  static let trackWidth: CGFloat = 4
  static let completedRadius: CGFloat = 7
  static let currentRadius: CGFloat = 11
  static let futureRadius: CGFloat = 6
  static let height: CGFloat = 34

  var body: some View {
    VStack(alignment: .leading, spacing: geometry.scaled(12)) {
      Text(label)
        .font(Typography.caps(geometry.scaled(11)))
        .tracking(geometry.scaled(11) * 0.16)
        .foregroundStyle(Palette.railLabel)
      rail
    }
    .frame(width: geometry.progressWidth, alignment: .leading)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(label)
  }

  private var rail: some View {
    ZStack(alignment: .topLeading) {
      track
      nodes
      glyphs
    }
    .frame(width: geometry.progressWidth, height: geometry.scaled(Self.height))
  }

  private var track: some View {
    ZStack(alignment: .leading) {
      Capsule()
        .fill(Palette.SceneShadow.meadow.opacity(0.22))
        .frame(width: trackSpan, height: thickness)
      if sentenceIndex > 0 {
        Capsule()
          .fill(Palette.amber)
          .frame(width: completedSpan, height: thickness)
      }
    }
    .position(x: centre(0) + trackSpan / 2, y: centreY)
  }

  private var thickness: CGFloat { geometry.scaled(Self.trackWidth) }
  private var lastIndex: Int { max(story.sentences.count - 1, 0) }
  private var trackSpan: CGFloat { centre(lastIndex) - centre(0) }
  private var completedSpan: CGFloat { centre(min(sentenceIndex, lastIndex)) - centre(0) }

  private func diameter(_ radius: CGFloat) -> CGFloat { geometry.scaled(radius * 2) }

  private var nodes: some View {
    ForEach(story.sentences.indices, id: \.self) { index in
      node(at: index)
        .position(x: centre(index), y: centreY)
    }
  }

  @ViewBuilder
  private func node(at index: Int) -> some View {
    if index < sentenceIndex {
      Circle()
        .fill(Palette.amber)
        .frame(width: diameter(Self.completedRadius), height: diameter(Self.completedRadius))
    } else if index == sentenceIndex {
      Circle()
        .fill(Palette.cream)
        .strokeBorder(Palette.amber, lineWidth: geometry.scaled(4))
        .frame(width: diameter(Self.currentRadius), height: diameter(Self.currentRadius))
    } else {
      Circle()
        .fill(.white.opacity(0.75))
        .frame(width: diameter(Self.futureRadius), height: diameter(Self.futureRadius))
    }
  }

  private var glyphs: some View {
    ForEach(milestones, id: \.index) { milestone in
      milestone.glyph
        .fill(Palette.SceneShadow.meadow.opacity(0.6))
        .frame(
          width: geometry.scaled(milestone.size.width),
          height: geometry.scaled(milestone.size.height)
        )
        .position(x: centre(milestone.index), y: geometry.scaled(6))
    }
  }

  private var milestones: [Milestone] {
    var wordsBefore = 0
    var seen: Set<WorldStage> = [.meadow]
    var found: [Milestone] = []
    for (index, sentence) in story.sentences.enumerated() {
      let stage = WorldStage(progress: Double(wordsBefore) * story.wordStep)
      if !seen.contains(stage) {
        seen.insert(stage)
        found.append(Milestone(index: index, stage: stage))
      }
      wordsBefore += sentence.words.count
    }
    return found
  }

  struct Milestone {
    let index: Int
    let stage: WorldStage

    var size: CGSize {
      stage == .castle ? CGSize(width: 14, height: 9) : CGSize(width: 16, height: 8)
    }

    var glyph: AnyShape {
      stage == .castle ? AnyShape(CastleGlyph()) : AnyShape(DragonGlyph())
    }
  }

  private var centreY: CGFloat { geometry.scaled(20) }

  private func centre(_ index: Int) -> CGFloat {
    let inset = geometry.scaled(Self.currentRadius)
    let span = geometry.progressWidth - inset * 2
    return inset + span * CGFloat(index) / CGFloat(max(lastIndex, 1))
  }

  private var label: String {
    let base = "SENTENCE \(sentenceIndex + 1) OF \(story.sentences.count)"
    guard let newWord = story.sentences[safe: sentenceIndex]?.newWord else { return base }
    return "\(base) · NEW WORD “\(newWord.uppercased())”"
  }
}

struct CastleGlyph: Shape {
  static let points: [CGPoint] = [
    CGPoint(x: 0, y: 3), CGPoint(x: 3, y: 3), CGPoint(x: 3, y: 0), CGPoint(x: 6, y: 0),
    CGPoint(x: 6, y: 3), CGPoint(x: 9, y: 3), CGPoint(x: 9, y: 0), CGPoint(x: 12, y: 0),
    CGPoint(x: 12, y: 3), CGPoint(x: 14, y: 3), CGPoint(x: 14, y: 9), CGPoint(x: 0, y: 9)
  ]

  func path(in rect: CGRect) -> Path {
    var path = Path()
    for (offset, point) in Self.points.enumerated() {
      let scaled = CGPoint(
        x: rect.minX + rect.width * point.x / 14,
        y: rect.minY + rect.height * point.y / 9
      )
      if offset == 0 {
        path.move(to: scaled)
      } else {
        path.addLine(to: scaled)
      }
    }
    path.closeSubpath()
    return path
  }
}

struct DragonGlyph: Shape {
  func path(in rect: CGRect) -> Path {
    let x = { (value: CGFloat) in rect.minX + rect.width * value / 16 }
    let y = { (value: CGFloat) in rect.minY + rect.height * value / 8 }
    var path = Path()
    path.move(to: CGPoint(x: x(0), y: y(6)))
    path.addQuadCurve(to: CGPoint(x: x(9), y: y(4)), control: CGPoint(x: x(4), y: y(0)))
    path.addQuadCurve(to: CGPoint(x: x(16), y: y(6)), control: CGPoint(x: x(13), y: y(0)))
    path.addQuadCurve(to: CGPoint(x: x(0), y: y(6)), control: CGPoint(x: x(8), y: y(8)))
    path.closeSubpath()
    return path
  }
}
