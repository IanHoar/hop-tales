import DesignSystem
import SwiftUI

struct ReadingTopBar: View {
  let title: String
  let stars: Int
  let geometry: ReadingGeometry
  let back: () -> Void

  var body: some View {
    HStack(spacing: 0) {
      BackButton(geometry: geometry, action: back)
      Spacer(minLength: geometry.scaled(8))
      StoryRibbon(title: title, geometry: geometry)
      Spacer(minLength: geometry.scaled(8))
      StarTotal(stars: stars, geometry: geometry)
    }
    .padding(.horizontal, geometry.scaled(16))
  }
}

struct BackButton: View {
  let geometry: ReadingGeometry
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: "chevron.left")
        .font(.system(size: geometry.scaled(19), weight: .heavy))
        .foregroundStyle(Paper.ink)
        .frame(width: geometry.scaled(48), height: geometry.scaled(48))
        .paperChip(Circle(), rim: geometry.scaled(4))
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Back to stories")
  }
}

struct PaperStar: View {
  let size: CGFloat

  var body: some View {
    Star()
      .fill(Paper.wash)
      .overlay(Star().stroke(Paper.washRing, lineWidth: max(1, size * 0.07)))
      .frame(width: size, height: size)
  }
}

struct StarTotal: View {
  let stars: Int
  let geometry: ReadingGeometry

  var body: some View {
    HStack(spacing: geometry.scaled(7)) {
      PaperStar(size: geometry.scaled(21))
      Text("\(stars)")
        .font(Typography.display(geometry.scaled(18)))
        .foregroundStyle(Paper.ink)
        .monospacedDigit()
    }
    .padding(.leading, geometry.scaled(12))
    .padding(.trailing, geometry.scaled(16))
    .frame(height: geometry.scaled(48))
    .paperChip(Capsule(), rim: geometry.scaled(4))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(stars) stars")
  }
}

struct StoryRibbon: View {
  let title: String
  let geometry: ReadingGeometry

  var body: some View {
    PaperLabel(seed: 5) {
      Text(title)
        .font(Typography.display(geometry.scaled(18)))
        .foregroundStyle(Paper.ink)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.horizontal, geometry.scaled(18))
        .padding(.vertical, geometry.scaled(9))
        .frame(maxWidth: geometry.scaled(210))
    }
    .rotationEffect(.degrees(-2))
    .accessibilityAddTraits(.isHeader)
  }
}
