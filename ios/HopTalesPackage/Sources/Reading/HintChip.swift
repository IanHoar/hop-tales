import DesignSystem
import SwiftUI

struct HintChip: View {
  static let title = "Hint?"

  let geometry: ReadingGeometry
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Label(Self.title, systemImage: "speaker.wave.2.fill")
        .font(Typography.ui(geometry.path(16), weight: .semibold))
        .foregroundStyle(Paper.ink)
        .lineLimit(1)
        .padding(.horizontal, geometry.path(14))
        .frame(height: geometry.path(38))
        .paperChip(Capsule(), rim: geometry.path(3))
        .frame(height: geometry.path(44))
        .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Hear the word")
  }
}

struct HintChipSlot: View {
  let isOffering: Bool
  let geometry: ReadingGeometry
  let action: () -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    ZStack {
      if isOffering {
        HintChip(geometry: geometry, action: action)
          .transition(transition.animation(.easeInOut(duration: 0.3)))
      }
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
  }

  private var transition: AnyTransition {
    reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.9, anchor: .topTrailing))
  }
}

#Preview {
  ZStack {
    Color(hex: 0x8FCB6B)
    HintChip(geometry: ReadingGeometry(size: Metrics.phone.reference)) {}
  }
  .frame(width: Metrics.phone.reference.width, height: 120)
}
