import Content
import DesignSystem
import SwiftUI

struct ProgressRail: View {
  let story: Story
  let sentenceIndex: Int
  let geometry: ReadingGeometry

  static let trackHeight: CGFloat = 12
  static let doneRadius: CGFloat = 10
  static let currentRadius: CGFloat = 13
  static let haloRadius: CGFloat = 17
  static let futureRadius: CGFloat = 8
  static let height: CGFloat = 58

  var body: some View {
    VStack(alignment: .leading, spacing: geometry.scaled(6)) {
      Text(label)
        .font(Typography.display(geometry.scaled(14)))
        .tracking(geometry.scaled(14) * 0.12)
        .foregroundStyle(Palette.labelOnWorld)
        .inkHalo(geometry.scaled(2))
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
    }
    .frame(width: geometry.progressWidth, height: geometry.scaled(Self.height))
  }

  private var outline: CGFloat { geometry.scaled(3) }

  private var track: some View {
    ZStack(alignment: .leading) {
      Capsule()
        .fill(isDusk ? Palette.trackDusk : Palette.track)
      if sentenceIndex > 0 {
        Capsule()
          .fill(Palette.gold)
          .frame(width: completedSpan + geometry.scaled(Self.trackHeight))
          .padding(geometry.scaled(2))
      }
    }
    .overlay(Capsule().strokeBorder(Palette.outline, lineWidth: outline))
    .frame(
      width: trackSpan + geometry.scaled(Self.trackHeight),
      height: geometry.scaled(Self.trackHeight)
    )
    .position(x: centre(0) + trackSpan / 2, y: centreY)
  }

  private var isDusk: Bool {
    [.dusk, .night].contains(story.mood(atSentence: sentenceIndex).sky)
  }

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
        .fill(Palette.gold)
        .overlay {
          Star()
            .fill(Palette.goldLight)
            .padding(geometry.scaled(4.5))
        }
        .overlay(Circle().strokeBorder(Palette.outline, lineWidth: outline))
        .frame(width: diameter(Self.doneRadius), height: diameter(Self.doneRadius))
    } else if index == sentenceIndex {
      ZStack {
        Circle()
          .fill(Palette.goldLight.opacity(0.5))
          .frame(width: diameter(Self.haloRadius), height: diameter(Self.haloRadius))
        Circle()
          .fill(Palette.parchment)
          .overlay(Circle().strokeBorder(Palette.outline, lineWidth: geometry.scaled(3.4)))
          .frame(width: diameter(Self.currentRadius), height: diameter(Self.currentRadius))
        Circle()
          .fill(Palette.ball)
          .overlay(Circle().strokeBorder(Palette.outline, lineWidth: geometry.scaled(2)))
          .frame(width: diameter(6), height: diameter(6))
      }
    } else {
      Circle()
        .fill(Palette.stone)
        .overlay(Circle().strokeBorder(Palette.outline, lineWidth: outline))
        .frame(width: diameter(Self.futureRadius), height: diameter(Self.futureRadius))
    }
  }

  private var centreY: CGFloat { geometry.scaled(38) }

  private func centre(_ index: Int) -> CGFloat {
    let inset = geometry.scaled(Self.haloRadius)
    let span = geometry.progressWidth - inset * 2
    return inset + span * CGFloat(index) / CGFloat(max(lastIndex, 1))
  }

  private var label: String {
    let base = sentenceIndex == story.sentences.count - 1
      ? "LAST SENTENCE!"
      : "SENTENCE \(sentenceIndex + 1) OF \(story.sentences.count)"
    guard let newWord = story.sentences[safe: sentenceIndex]?.newWord else { return base }
    return "NEW WORD · \(newWord.uppercased())"
  }
}
