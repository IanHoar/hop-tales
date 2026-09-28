import DesignSystem
import SwiftUI

struct NoiseCue: View {
  static let title = "It's a bit noisy here"
  static let detail = "Background noise makes the words hard to hear. Somewhere quieter will help."

  let geometry: ReadingGeometry

  var body: some View {
    VStack(alignment: .leading, spacing: geometry.path(4)) {
      Label(Self.title, systemImage: "waveform")
        .font(Typography.display(geometry.path(16)))
        .foregroundStyle(Paper.ink)
        .labelStyle(TipLabelStyle(geometry: geometry))
      Text(Self.detail)
        .font(Typography.ui(geometry.path(13), weight: .medium))
        .foregroundStyle(Paper.ink.opacity(0.85))
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.horizontal, geometry.path(14))
    .padding(.vertical, geometry.path(10))
    .frame(width: geometry.path(250), alignment: .leading)
    .paperChip(RoundedRectangle(cornerRadius: geometry.path(16)), rim: geometry.path(3))
    .accessibilityElement(children: .combine)
    .onAppear {
      AccessibilityNotification.Announcement("\(Self.title). \(Self.detail)").post()
    }
  }
}

struct NoiseCueSlot: View {
  let isNoisy: Bool
  let geometry: ReadingGeometry

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    ZStack {
      if isNoisy {
        NoiseCue(geometry: geometry)
          .transition(transition.animation(.easeInOut(duration: 0.35)))
      }
    }
    .frame(maxWidth: .infinity)
  }

  private var transition: AnyTransition {
    reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.92, anchor: .top))
  }
}

#Preview {
  ZStack {
    Color(hex: 0x8FCB6B)
    NoiseCue(geometry: ReadingGeometry(size: Metrics.phone.reference))
  }
  .frame(width: Metrics.phone.reference.width, height: 160)
}
