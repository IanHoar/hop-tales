import DesignSystem
import SwiftUI

struct MicPill: View {
  let heardToken: String?
  let geometry: ReadingGeometry
  var animatesBars = true

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  static let barHeights: [CGFloat] = [7, 14, 9, 17, 6]
  static let barPeriods: [TimeInterval] = [0.42, 0.55, 0.36, 0.48, 0.39]
  static let barRange: ClosedRange<CGFloat> = 6...17

  var body: some View {
    HStack(spacing: geometry.scaled(heardToken == nil ? 12 : 10)) {
      if let heardToken {
        Image(systemName: "checkmark")
          .font(.system(size: geometry.scaled(15), weight: .bold))
          .foregroundStyle(Palette.heardText)
        Text("Heard it — “\(heardToken)”")
          .font(Typography.ui(geometry.scaled(15)))
          .foregroundStyle(Palette.heardText)
      } else {
        Image(systemName: "mic")
          .font(.system(size: geometry.scaled(17), weight: .medium))
          .foregroundStyle(Palette.ink)
        bars
        Text("Say the word")
          .font(Typography.ui(geometry.scaled(15)))
          .foregroundStyle(Palette.chipText)
      }
    }
    .padding(.horizontal, geometry.scaled(22))
    .padding(.vertical, geometry.scaled(13))
    .frame(minHeight: geometry.minimumTouchTarget)
    .background {
      Capsule()
        .fill(heardToken == nil ? Palette.cream : Palette.heardBg)
        .shadow(color: Palette.ink.opacity(0.10), radius: 0, x: 0, y: geometry.scaled(6))
        .shadow(
          color: Palette.SceneShadow.meadow.opacity(0.16),
          radius: geometry.scaled(24),
          x: 0,
          y: geometry.scaled(14)
        )
    }
    .animation(Motion.recognised, value: heardToken)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(heardToken.map { "Heard \($0)" } ?? "Listening. Say the word out loud.")
  }

  private var bars: some View {
    HStack(alignment: .bottom, spacing: geometry.scaled(3)) {
      ForEach(Array(Self.barHeights.enumerated()), id: \.offset) { index, height in
        Bar(
          restingHeight: geometry.scaled(height),
          period: Self.barPeriods[index],
          isAnimating: animatesBars && !reduceMotion,
          geometry: geometry
        )
      }
    }
    .frame(height: geometry.scaled(18), alignment: .bottom)
  }

  private struct Bar: View {
    let restingHeight: CGFloat
    let period: TimeInterval
    let isAnimating: Bool
    let geometry: ReadingGeometry

    @State private var extended = false

    var body: some View {
      Capsule()
        .fill(Palette.listenBars)
        .frame(
          width: geometry.scaled(4),
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
