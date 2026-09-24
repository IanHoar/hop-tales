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
        .font(Typography.display(geometry.scaled(19)))
        .foregroundStyle(heardToken == nil ? Paper.ink : Paper.sageDeep)
        .lineLimit(1)
    }
    .padding(.leading, geometry.scaled(8))
    .padding(.trailing, geometry.scaled(22))
    .frame(height: geometry.scaled(64))
    .paperChip(Capsule(), rim: geometry.scaled(5), shadow: 1.3)
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
      .font(.system(size: geometry.scaled(18), weight: .bold))
      .foregroundStyle(Paper.onRed)
      .frame(width: geometry.scaled(40), height: geometry.scaled(40))
      .background(heardToken == nil ? Paper.sage : Paper.sageDeep, in: .circle)
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
        .fill(Paper.sageDeep)
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
