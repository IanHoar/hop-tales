import DesignSystem
import SwiftUI

struct Ball: View {
  let wordIndex: Int
  var completionCount = 0
  let geometry: ReadingGeometry
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.freezesMotion) private var freezesMotion
  @State private var physics = BallPhysics()
  private var radius: CGFloat { geometry.scaled(geometry.metrics.ballRadius) }
  private var centerY: CGFloat { geometry.scaled(48) }
  private var shadowY: CGFloat { geometry.scaled(70) }

  var body: some View {
    Group {
      if freezesMotion {
        scene(.resting)
      } else {
        TimelineView(.animation) { context in
          scene(physics.pose(at: Self.seconds(context.date), reduceMotion: reduceMotion))
        }
      }
    }
    .frame(width: geometry.cardSize.width, height: geometry.ballLaneHeight)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
    .onChange(of: wordIndex) { _, _ in
      physics.jump(at: Self.seconds(.now), reduceMotion: reduceMotion)
    }
    .onChange(of: completionCount) { _, _ in doubleHop() }
  }

  static func seconds(_ date: Date) -> TimeInterval {
    date.timeIntervalSinceReferenceDate
  }

  private func scene(_ pose: BallPhysics.Pose) -> some View {
    ZStack(alignment: .top) {
      shadow(height: min(pose.height / BallPhysics.jumpApex, 1))
      sphere
        .frame(width: radius * 2, height: radius * 2)
        .scaleEffect(x: pose.scaleX, y: pose.scaleY, anchor: .bottom)
        .position(x: geometry.cardSize.width / 2, y: centerY)
        .offset(y: -geometry.scaled(pose.height))
    }
  }

  private func shadow(height: CGFloat) -> some View {
    Ellipse()
      .fill(Palette.ink.opacity(0.14 * (1 - 0.5 * height)))
      .frame(width: geometry.scaled(34) * (1 - 0.35 * height), height: geometry.scaled(8))
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
    let now = Self.seconds(.now)
    let landing = BallPhysics.timeToLanding(from: physics.pose(at: now).height)
    physics.jump(at: now)
    Task { @MainActor in
      try? await Task.sleep(for: .seconds(landing))
      physics.jump(at: Self.seconds(.now))
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
