import DesignSystem
import SwiftUI

struct Ball: View {
  let wordIndex: Int
  var completionCount = 0
  let geometry: ReadingGeometry
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var arcOffset: CGFloat = 0
  private var radius: CGFloat { geometry.scaled(geometry.metrics.ballRadius) }
  private var centerY: CGFloat { geometry.scaled(48) }
  private var shadowY: CGFloat { geometry.scaled(70) }
  private var apex: CGFloat {
    geometry.scaled(reduceMotion ? Motion.reducedHopOffset : Motion.ballApexIdle)
  }

  var body: some View {
    KeyframeAnimator(initialValue: Hop(), repeating: true) { hop in
      let offset = hop.y * apex + arcOffset
      ZStack(alignment: .top) {
        shadow(height: height(of: offset))
        sphere
          .frame(width: radius * 2, height: radius * 2)
          .scaleEffect(x: hop.scaleX, y: hop.scaleY, anchor: .bottom)
          .position(x: geometry.cardSize.width / 2, y: centerY)
          .offset(y: offset)
      }
    } keyframes: { _ in
      Hop.track(squash: !reduceMotion)
    }
    .frame(width: geometry.cardSize.width, height: geometry.ballLaneHeight)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
    .onChange(of: wordIndex) { _, _ in arc() }
    .onChange(of: completionCount) { _, _ in doubleHop() }
  }

  private func height(of offset: CGFloat) -> CGFloat {
    guard apex != 0 else { return 0 }
    return min(abs(offset / apex), 1)
  }

  private func shadow(height: CGFloat) -> some View {
    Ellipse()
      .fill(Palette.ink.opacity(0.14 * (1 - 0.4 * height)))
      .frame(width: geometry.scaled(34) * (1 - 0.25 * height), height: geometry.scaled(8))
      .position(x: geometry.cardSize.width / 2, y: shadowY)
  }

  private var sphere: some View {
    Circle()
      .fill(
        RadialGradient(
          colors: [Palette.ballHi, Palette.ball, Palette.ballLo],
          center: UnitPoint(x: 0.35, y: 0.3),
          startRadius: 0,
          endRadius: radius * 1.6
        )
      )
      .overlay(alignment: .topLeading) {
        Circle()
          .fill(Color(hex: 0xFFF1DC, opacity: 0.9))
          .frame(width: radius * 0.52, height: radius * 0.52)
          .offset(x: radius * 0.18, y: radius * 0.22)
      }
  }

  private func doubleHop() {
    guard !reduceMotion else { return }
    arc()
    Task {
      try? await Task.sleep(for: .milliseconds(260))
      arc()
    }
  }

  private func arc() {
    guard !reduceMotion else { return }
    let extra = geometry.scaled(Motion.ballApexRecognised - Motion.ballApexIdle)
    withAnimation(.easeOut(duration: 0.225)) {
      arcOffset = extra
    } completion: {
      withAnimation(.easeIn(duration: 0.225)) {
        arcOffset = 0
      }
    }
  }
}

struct Hop {
  var y: CGFloat = 0
  var scaleX: CGFloat = 1
  var scaleY: CGFloat = 1
  @KeyframesBuilder<Hop>
  static func track(squash: Bool) -> some Keyframes<Hop> {
    KeyframeTrack(\Hop.y) {
      CubicKeyframe(1, duration: 0.33, startVelocity: 4.4, endVelocity: 0)
      CubicKeyframe(0, duration: 0.33, startVelocity: 0, endVelocity: -4.4)

      LinearKeyframe(0, duration: 0.06)
    }
    KeyframeTrack(\Hop.scaleX) {
      LinearKeyframe(squash ? 0.97 : 1, duration: 0.33)
      LinearKeyframe(1, duration: 0.29)
      SpringKeyframe(squash ? 1.12 : 1, duration: 0.04, spring: .snappy)
      SpringKeyframe(1, duration: 0.06, spring: .bouncy)
    }
    KeyframeTrack(\Hop.scaleY) {
      LinearKeyframe(squash ? 1.04 : 1, duration: 0.33)
      LinearKeyframe(1, duration: 0.29)
      SpringKeyframe(squash ? 0.88 : 1, duration: 0.04, spring: .snappy)
      SpringKeyframe(1, duration: 0.06, spring: .bouncy)
    }
  }
}

#Preview("Ball") {
  @Previewable @State var wordIndex = 0
  GeometryReader { proxy in
    let geometry = ReadingGeometry(size: proxy.size)
    ZStack {
      Color(hex: 0x8FCB6B).ignoresSafeArea()
      VStack(spacing: geometry.scaled(40)) {
        Ball(wordIndex: wordIndex, geometry: geometry)
          .background(Palette.cream)
        Button("Read a word") { wordIndex += 1 }
          .font(Typography.ui(17))
          .buttonStyle(.borderedProminent)
      }
    }
  }
}
