import DesignSystem
import SwiftUI

struct MicPill: View {
  let heardToken: String?
  var hearing: String?
  let geometry: ReadingGeometry
  var animatesBars = true

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  static let barHeights: [CGFloat] = [7, 14, 9, 17, 6]
  static let barPeriods: [TimeInterval] = [0.42, 0.55, 0.36, 0.48, 0.39]
  static let barRange: ClosedRange<CGFloat> = 6...19

  var body: some View {
    HStack(spacing: geometry.scaled(12)) {
      disc
      if heardToken == nil {
        bars
      }
      Text(label)
        .font(Typography.ui(geometry.scaled(17)))
        .foregroundStyle(heardToken == nil ? Palette.ink : Palette.heardText)
        .lineLimit(1)
    }
    .padding(.leading, geometry.scaled(10))
    .padding(.trailing, geometry.scaled(22))
    .frame(height: geometry.scaled(56))
    .bevel(
      heardToken == nil ? Palette.parchment : Palette.heardBg,
      lip: heardToken == nil ? Palette.parchmentLip : Palette.heardLip,
      shape: Capsule(),
      border: geometry.scaled(3),
      drop: geometry.scaled(4)
    )
    .animation(Motion.recognised, value: heardToken)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(heardToken.map { "Heard \($0)" } ?? "Listening. Say the word out loud.")
  }

  private var label: String {
    if let heardToken { return "Heard it — “\(heardToken)”!" }
    return hearing.map { "Hearing “\($0)”" } ?? "Say the word"
  }

  private var disc: some View {
    Image(systemName: heardToken == nil ? "mic.fill" : "checkmark")
      .font(.system(size: geometry.scaled(16), weight: .heavy))
      .foregroundStyle(.white)
      .frame(width: geometry.scaled(36), height: geometry.scaled(36))
      .background(heardToken == nil ? Palette.teal : Palette.heardIcon, in: .circle)
      .overlay(Circle().strokeBorder(Palette.outline, lineWidth: geometry.scaled(3)))
  }

  private var bars: some View {
    HStack(alignment: .bottom, spacing: geometry.scaled(3.5)) {
      ForEach(Array(Self.barHeights.enumerated()), id: \.offset) { index, height in
        Bar(
          restingHeight: geometry.scaled(height),
          period: Self.barPeriods[index],
          isAnimating: animatesBars && !reduceMotion,
          geometry: geometry
        )
      }
    }
    .frame(height: geometry.scaled(20), alignment: .bottom)
  }

  private struct Bar: View {
    let restingHeight: CGFloat
    let period: TimeInterval
    let isAnimating: Bool
    let geometry: ReadingGeometry

    @State private var extended = false

    var body: some View {
      RoundedRectangle(cornerRadius: geometry.scaled(3))
        .fill(Palette.teal)
        .overlay {
          RoundedRectangle(cornerRadius: geometry.scaled(3))
            .strokeBorder(Palette.outline, lineWidth: geometry.scaled(1.5))
        }
        .frame(
          width: geometry.scaled(6),
          height: extended ? geometry.scaled(MicPill.barRange.upperBound) : restingHeight
        )
        .onAppear {
          guard isAnimating else { return }
          withAnimation(.easeInOut(duration: period).repeatForever(autoreverses: true)) {
            extended = true
          }
        }
    }
  }
}
