import Content
import DesignSystem
import SwiftUI
import World

struct FriendReveal: View {
  enum Stage: Int, Comparable {
    case hidden
    case shaking
    case revealed
    case settled

    static func < (lhs: Stage, rhs: Stage) -> Bool { lhs.rawValue < rhs.rawValue }
  }

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.freezesMotion) private var freezesMotion
  let friend: Friend
  let geometry: ReadingGeometry
  @State private var played: Stage?
  @State private var spin = false

  private var stage: Stage { played ?? (reduceMotion || freezesMotion ? .settled : .hidden) }
  private var height: CGFloat { geometry.path(104) }

  var body: some View {
    ZStack {
      Sunburst(rays: 14)
        .fill(RadialGradient(
          colors: [Paper.wash.opacity(0.75), Paper.wash.opacity(0)],
          center: .center, startRadius: 0, endRadius: height * 0.8
        ))
        .frame(width: height * 1.6, height: height * 1.6)
        .rotationEffect(.degrees(spin ? 360 : 0))
        .scaleEffect(stage >= .revealed ? 1 : 0.2)
        .opacity(stage >= .revealed ? 1 : 0)
      sparkles
      FriendSticker(friend, height: height, isSilhouette: true)
        .opacity(stage >= .revealed ? 0 : 0.7)
        .scaleEffect(stage >= .revealed ? 1.3 : 0.9)
        .keyframeAnimator(initialValue: 0.0, trigger: stage == .shaking) { content, angle in
          content.rotationEffect(.degrees(angle), anchor: .bottom)
        } keyframes: { _ in
          KeyframeTrack {
            for swing in [3.0, -3, 5, -5, 7, -7, 9, -9] {
              CubicKeyframe(swing, duration: 0.11)
            }
            CubicKeyframe(0, duration: 0.1)
          }
        }
      FriendSticker(friend, height: height)
        .scaleEffect(stage >= .revealed ? 1 : 0.3, anchor: .bottom)
        .opacity(stage >= .revealed ? 1 : 0)
        .keyframeAnimator(initialValue: 0.0, trigger: stage == .settled) { content, lift in
          content.offset(y: -lift)
        } keyframes: { _ in
          KeyframeTrack {
            CubicKeyframe(geometry.path(16), duration: 0.18)
            CubicKeyframe(0, duration: 0.18)
            CubicKeyframe(geometry.path(6), duration: 0.14)
            CubicKeyframe(0, duration: 0.14)
          }
        }
      companions
    }
    .frame(height: geometry.path(150))
    .sensoryFeedback(.success, trigger: stage == .revealed)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(friend.name), your new friend")
    .task { await play() }
  }

  private var sparkles: some View {
    ForEach(0..<8, id: \.self) { index in
      let angle = Double(index) * .pi / 4 + .pi / 8
      let reach = stage >= .revealed ? height * (index.isMultiple(of: 2) ? 0.78 : 0.62) : 0
      Sticker("collect-star", height: geometry.path(index.isMultiple(of: 2) ? 20 : 14))
        .offset(x: cos(angle) * reach, y: sin(angle) * reach * 0.8)
        .scaleEffect(stage == .revealed ? 1 : 0.2)
        .opacity(stage == .revealed ? 1 : 0)
    }
  }

  private var companions: some View {
    ZStack {
      FriendSticker(Friend.at(level: friend.level - 1), height: geometry.path(60))
        .offset(x: -height * 0.95, y: height / 2 - geometry.path(30))
        .offset(x: stage == .settled ? 0 : -geometry.path(30))
        .opacity(stage == .settled ? 1 : 0)
      ZStack {
        Sticker("collect-rosette", height: geometry.path(56))
        Text("\(friend.level)")
          .font(Typography.display(geometry.path(18)))
          .foregroundStyle(Paper.ink)
          .offset(y: -geometry.path(5))
      }
      .rotationEffect(.degrees(stage == .settled ? 8 : -40))
      .scaleEffect(stage == .settled ? 1 : 0.2)
      .opacity(stage == .settled ? 1 : 0)
      .offset(x: height * 0.85, y: -geometry.path(38))
    }
  }

  private func play() async {
    guard played == nil, stage == .hidden else { return }
    played = .hidden
    try? await Task.sleep(for: .milliseconds(300))
    played = .shaking
    try? await Task.sleep(for: .milliseconds(1_000))
    withAnimation(.spring(duration: 0.55, bounce: 0.5)) { played = .revealed }
    withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) { spin = true }
    try? await Task.sleep(for: .milliseconds(900))
    withAnimation(.spring(duration: 0.5, bounce: 0.35)) { played = .settled }
  }
}

struct Sunburst: Shape {
  var rays: Int

  func path(in rect: CGRect) -> Path {
    let centre = CGPoint(x: rect.midX, y: rect.midY)
    let radius = min(rect.width, rect.height) / 2
    let half = Double.pi / Double(rays) / 2
    var path = Path()
    for ray in 0..<rays {
      let angle = Double(ray) * 2 * .pi / Double(rays)
      path.move(to: centre)
      path.addArc(
        center: centre, radius: radius,
        startAngle: .radians(angle - half), endAngle: .radians(angle + half), clockwise: false
      )
      path.closeSubpath()
    }
    return path
  }
}
