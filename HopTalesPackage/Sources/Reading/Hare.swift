import Content
import DesignSystem
import SwiftUI
import World

struct HopTarget: Hashable {
  var sentence: Int
  var word: Int
}

struct HopPlan {
  var distance: CGFloat = 0
  var carried = false
}

struct Hare: View {
  let target: HopTarget
  let geometry: ReadingGeometry
  var hop: (HopTarget) -> HopPlan = { _ in HopPlan() }
  var onSettle: (HopTarget, Animation?) -> Void = { _, _ in }
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.freezesMotion) private var freezesMotion
  @State private var motion = HareMotion()
  @State private var hops = 0

  static let height: CGFloat = 176
  static let feetBelowCardTop: CGFloat = 14

  var body: some View {
    Group {
      if freezesMotion {
        scene(.resting)
      } else {
        TimelineView(.animation) { context in
          scene(motion.pose(at: Self.seconds(context.date), reduceMotion: reduceMotion))
        }
      }
    }
    .frame(width: geometry.cardSize.width, height: 0)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
    .onChange(of: target) { _, target in hop(to: target) }
  }

  static func seconds(_ date: Date) -> TimeInterval {
    date.timeIntervalSinceReferenceDate
  }

  private func scene(_ pose: HareMotion.Pose) -> some View {
    let centre = geometry.cardSize.width / 2 + pose.x
    let airborne = pose.frame.sheet == .hop && (2...5).contains(pose.frame.index)
    return ZStack {
      Ellipse()
        .fill(
          RadialGradient(
            colors: [Paper.shadow.opacity(1.6), .clear],
            center: .center,
            startRadius: 0,
            endRadius: geometry.scaled(46)
          )
        )
        .frame(width: geometry.scaled(airborne ? 60 : 92), height: geometry.scaled(16))
        .opacity(airborne ? 0.45 : 1)
        .position(x: centre, y: 0)
      HareSprite(pose.frame, height: geometry.scaled(Self.height))
        .scaleEffect(x: pose.scaleX, y: pose.scaleY, anchor: .center)
        .position(x: centre, y: -geometry.scaled(pose.lift))
    }
  }

  private func hop(to target: HopTarget) {
    guard !reduceMotion, !freezesMotion else {
      onSettle(target, reduceMotion ? Motion.slide : nil)
      return
    }
    let plan = hop(target)
    let landing = motion.jump(
      at: Self.seconds(.now), distance: plan.distance, carried: plan.carried
    )
    hops += 1
    let current = hops
    if plan.carried {
      onSettle(target, .timingCurve(Motion.rideCurve, duration: landing))
      return
    }
    Task { @MainActor in
      try? await Task.sleep(for: .seconds(landing))
      guard hops == current else { return }
      onSettle(target, Motion.slide)
    }
  }
}

#Preview("Hare") {
  @Previewable @State var wordIndex = 0
  GeometryReader { proxy in
    let geometry = ReadingGeometry(size: proxy.size)
    VStack(spacing: 40) {
      Spacer()
      WordCard(
        words: StoryLibrary.all[0].sentences[0].words,
        currentIndex: wordIndex,
        geometry: geometry
      )
      Button("Read a word") { wordIndex += 1 }
        .buttonStyle(.borderedProminent)
      Spacer()
    }
    .frame(maxWidth: .infinity)
    .background(Paper.sage)
  }
}
