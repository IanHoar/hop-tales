import DesignSystem
import SwiftUI

struct StarChip: View {
  let stars: Int
  let geometry: ReadingGeometry
  var isAnimating = true

  static let duration: TimeInterval = 0.9
  static let rise: CGFloat = 24

  @State private var lift: CGFloat = 0
  @State private var opacity: Double = 0

  var body: some View {
    Text("+\(stars) star\(stars == 1 ? "" : "s")")
      .font(Typography.ui(geometry.scaled(14)))
      .foregroundStyle(Palette.flashText)
      .padding(.horizontal, geometry.scaled(14))
      .padding(.vertical, geometry.scaled(7))
      .background {
        Capsule()
          .fill(Palette.amber)
          .shadow(color: Palette.amberDeep.opacity(0.35), radius: 0, x: 0, y: geometry.scaled(4))
      }
      .offset(y: lift)
      .opacity(opacity)
      .task {
        guard isAnimating else {
          opacity = 1
          return
        }
        withAnimation(.easeOut(duration: Self.duration * 0.2)) { opacity = 1 }
        withAnimation(.easeOut(duration: Self.duration)) { lift = -geometry.scaled(Self.rise) }
        try? await Task.sleep(for: .seconds(Self.duration * 0.35))
        withAnimation(.easeIn(duration: Self.duration * 0.65)) { opacity = 0 }
      }
      .accessibilityHidden(true)
  }
}
