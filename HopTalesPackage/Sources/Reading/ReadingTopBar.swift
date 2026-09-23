import DesignSystem
import SwiftUI

struct ReadingTopBar: View {
  let title: String
  let stars: Int
  let geometry: ReadingGeometry
  let back: () -> Void

  var body: some View {
    HStack(spacing: 0) {
      Button(action: back) {
        Image(systemName: "chevron.left")
          .font(.system(size: geometry.scaled(22), weight: .heavy))
          .foregroundStyle(Palette.ink)
          .frame(width: geometry.scaled(52), height: geometry.scaled(52))
          .parchmentBevel(Circle(), border: geometry.scaled(3), drop: geometry.scaled(4))
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Back to stories")
      Spacer(minLength: geometry.scaled(8))
      StoryRibbon(title: title, geometry: geometry)
      Spacer(minLength: geometry.scaled(8))
      StarTotal(stars: stars, geometry: geometry)
    }
    .padding(.horizontal, geometry.scaled(16))
  }
}

struct StarTotal: View {
  let stars: Int
  let geometry: ReadingGeometry

  var body: some View {
    HStack(spacing: geometry.scaled(8)) {
      Coin(size: geometry.scaled(38))
      Text("\(stars)")
        .font(Typography.display(geometry.scaled(22)))
        .foregroundStyle(Palette.ink)
        .monospacedDigit()
    }
    .padding(.leading, geometry.scaled(6))
    .padding(.trailing, geometry.scaled(16))
    .frame(height: geometry.scaled(52))
    .parchmentBevel(Capsule(), border: geometry.scaled(3), drop: geometry.scaled(4))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(stars) stars")
  }
}

struct StoryRibbon: View {
  let title: String
  let geometry: ReadingGeometry

  var body: some View {
    Text(title)
      .font(Typography.display(geometry.scaled(17)))
      .foregroundStyle(Palette.labelOnWorld)
      .inkHalo(geometry.scaled(2))
      .lineLimit(1)
      .minimumScaleFactor(0.7)
      .padding(.horizontal, geometry.scaled(26))
      .frame(minWidth: geometry.scaled(160), maxWidth: geometry.scaled(230))
      .frame(height: geometry.scaled(52))
      .background {
        RibbonShape(tail: geometry.scaled(18), notch: geometry.scaled(9))
          .fill(Palette.redShade)
          .overlay(
            RibbonShape(tail: geometry.scaled(18), notch: geometry.scaled(9))
              .stroke(Palette.outline, lineWidth: geometry.scaled(3))
          )
          .offset(y: geometry.scaled(6))
          .padding(.vertical, geometry.scaled(8))
      }
      .background {
        Rectangle()
          .fill(Palette.red)
          .overlay(alignment: .top) {
            Rectangle()
              .fill(Palette.redLight)
              .frame(height: geometry.scaled(3))
              .padding(.top, geometry.scaled(4))
          }
          .overlay(Rectangle().strokeBorder(Palette.outline, lineWidth: geometry.scaled(3)))
          .padding(.horizontal, geometry.scaled(16))
          .padding(.top, geometry.scaled(4))
          .padding(.bottom, geometry.scaled(2))
      }
      .accessibilityAddTraits(.isHeader)
  }
}

struct RibbonShape: Shape {
  let tail: CGFloat
  let notch: CGFloat

  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.minX + tail, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.minX + tail, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX + notch, y: rect.midY))
    path.closeSubpath()
    path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX - tail, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX - tail, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.midY))
    path.closeSubpath()
    return path
  }
}
