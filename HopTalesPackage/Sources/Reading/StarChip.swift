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
    HStack(spacing: geometry.scaled(6)) {
      PaperStar(size: geometry.scaled(18))
      Text("+\(stars)")
        .font(Typography.display(geometry.scaled(17)))
        .foregroundStyle(Paper.ink)
    }
    .padding(.leading, geometry.scaled(9))
    .padding(.trailing, geometry.scaled(12))
    .frame(height: geometry.scaled(36))
    .paperChip(Capsule(), fill: Paper.wash, rim: geometry.scaled(3))
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
