import DesignSystem
import SwiftUI

/// The ball that sits above the current word and hops (`docs/HANDOFF.md` §4).
///
/// It idles at the card's centre because the current word is pinned there. When a word is read the
/// ball arcs up and settles while the row slides the next word underneath it.
struct Ball: View {
  /// Changes whenever a word is read, which is what triggers the arc.
  let wordIndex: Int
  let geometry: ReadingGeometry

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var idleOffset: CGFloat = 0
  @State private var arcOffset: CGFloat = 0

  /// Artboard geometry inside the 78pt lane: ball centre at y 48, shadow at y 70.
  private var radius: CGFloat { geometry.scaled(geometry.metrics.ballRadius) }
  private var centerY: CGFloat { geometry.scaled(48) }
  private var shadowY: CGFloat { geometry.scaled(70) }

  private var offset: CGFloat { idleOffset + arcOffset }

  /// How high the ball is right now, 0 (resting) to 1 (top of an idle hop). The shadow shrinks and
  /// fades as it climbs.
  private var height: CGFloat {
    min(abs(offset) / geometry.scaled(abs(Motion.ballApexIdle)), 1)
  }

  var body: some View {
    ZStack(alignment: .top) {
      Ellipse()
        .fill(Palette.ink.opacity(0.14 * (1 - 0.4 * height)))
        .frame(width: geometry.scaled(34) * (1 - 0.25 * height), height: geometry.scaled(8))
        .position(x: 0, y: shadowY)
        .offset(x: geometry.cardSize.width / 2)

      sphere
        .frame(width: radius * 2, height: radius * 2)
        .position(x: geometry.cardSize.width / 2, y: centerY)
        .offset(y: offset)
    }
    .frame(width: geometry.cardSize.width, height: geometry.ballLaneHeight)
    .allowsHitTesting(false)
    .onAppear(perform: startIdleHop)
    .onChange(of: wordIndex) { _, _ in arc() }
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

  private func startIdleHop() {
    // Reduce Motion keeps a small bob so the ball still reads as alive, without the travel.
    let apex = reduceMotion ? Motion.reducedHopOffset : Motion.ballApexIdle
    withAnimation(Motion.idleHop) {
      idleOffset = geometry.scaled(apex)
    }
  }

  /// The recognised hop: up to apex −46 and back down over 0.45s, on top of the idle bounce.
  private func arc() {
    guard !reduceMotion else { return }
    let apex = geometry.scaled(Motion.ballApexRecognised - Motion.ballApexIdle)
    withAnimation(.easeOut(duration: 0.225)) {
      arcOffset = apex
    } completion: {
      withAnimation(.easeIn(duration: 0.225)) {
        arcOffset = 0
      }
    }
  }
}

/// Interactive: "Read a word" fires the arc, which is otherwise unreachable until speech lands.
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
