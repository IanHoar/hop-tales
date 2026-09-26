import DesignSystem
import SwiftUI
import World

struct PathWord: View {
  @Environment(\.freezesMotion) private var freezesMotion
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var popped = false
  @State private var floated = false
  let text: String
  var leading = ""
  var trailing = ""
  let state: PathWordState
  let size: CGFloat
  let overhang: CGFloat
  var isBig = false
  var isPulsing = false
  var chalk = false

  var body: some View {
    Text(text)
      .font(Typography.word(size))
      .foregroundStyle(chalk ? state.chalk : state.ink)
      .lineLimit(1)
      .fixedSize()
      .background {
        PathWash()
          .padding(.horizontal, -overhang)
          .opacity(state == .read ? 1 : 0)
          .animation(.easeOut(duration: 0.35).delay(0.25), value: state == .read)
      }
      .overlay(alignment: .leading) {
        punctuation(leading)
          .alignmentGuide(.leading) { $0[.trailing] }
      }
      .overlay(alignment: .trailing) {
        punctuation(trailing)
          .alignmentGuide(.trailing) { $0[.leading] }
      }
      .overlay(alignment: .bottom) {
        if isBig { underline }
      }
      .overlay(alignment: .top) {
        if isBig { star }
      }
      .scaleEffect(scale)
      .animation(.easeInOut(duration: 0.3), value: state)
      .animation(.easeInOut(duration: 0.28).repeatCount(3, autoreverses: true), value: isPulsing)
      .rotation3DEffect(
        .degrees(freezesMotion ? 0 : 24),
        axis: (x: 1, y: 0, z: 0),
        anchor: UnitPoint(x: 0.5, y: 0.6),
        perspective: 0.5
      )
      .blendMode(chalk ? .screen : .multiply)
      .allowsHitTesting(false)
      .accessibilityHidden(true)
      .onChange(of: state) { _, state in
        guard isBig, state == .read, !reduceMotion else { return }
        withAnimation(.easeOut(duration: 0.3)) { popped = true }
        withAnimation(.easeOut(duration: 0.9).delay(0.1)) { floated = true }
      }
  }

  private func punctuation(_ marks: String) -> some View {
    Text(marks)
      .font(Typography.word(size))
      .foregroundStyle((chalk ? state.chalk : state.ink).opacity(0.7))
      .fixedSize()
      .accessibilityHidden(true)
  }

  private var underline: some View {
    let solid = state == .read && reduceMotion
    return Capsule()
      .stroke(
        PathWash.gold,
        style: StrokeStyle(
          lineWidth: size * 0.07, lineCap: .round, dash: solid ? [] : [1, size * 0.16]
        )
      )
      .frame(height: size * 0.07)
      .padding(.horizontal, size * 0.05)
      .offset(y: -size * 0.12)
  }

  @ViewBuilder
  private var star: some View {
    let read = state == .read
    ZStack {
      if !read || popped {
        Sticker("collect-star", height: size * 0.42)
          .scaleEffect(popped ? 0 : read ? 1.4 : 1)
          .opacity(popped ? 0 : 1)
      }
      if popped {
        Text("+5")
          .font(Typography.display(size * 0.4))
          .foregroundStyle(Paper.ink)
          .offset(y: floated ? -size * 0.9 : -size * 0.2)
          .opacity(floated ? 0 : 1)
      }
    }
    .offset(y: -size * 0.5)
  }

  private var scale: CGFloat {
    let big = isBig ? WordPath.bigWordScale : 1
    guard state == .current else { return WordPath.sideScale * big }
    return (isPulsing ? 1.08 : 1) * big
  }
}

struct PathWash: View {
  static let gold = Color(hex: 0xF7D774)

  var body: some View {
    Rectangle()
      .fill(
        EllipticalGradient(
          stops: [
            .init(color: Self.gold.opacity(0.95), location: 0),
            .init(color: Self.gold.opacity(0.7), location: 0.52),
            .init(color: Self.gold.opacity(0), location: 0.72)
          ],
          center: .center,
          startRadiusFraction: 0,
          endRadiusFraction: 0.5 * 2.squareRoot()
        )
      )
  }
}
