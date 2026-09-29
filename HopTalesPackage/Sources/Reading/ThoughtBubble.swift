import DesignSystem
import SwiftUI
import World

struct ThoughtBubble: View {
  static let width: CGFloat = 112
  static let height: CGFloat = 96

  static func size(in geometry: ReadingGeometry) -> CGSize {
    CGSize(width: geometry.path(width), height: geometry.path(height))
  }

  let art: String
  let geometry: ReadingGeometry

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      Sticker(art, height: geometry.path(46))
        .frame(width: geometry.path(96), height: geometry.path(66))
        .paperChip(Ellipse(), rim: geometry.path(3))
        .offset(x: geometry.path(16), y: -geometry.path(30))
      Circle()
        .fill(Paper.paper)
        .frame(width: geometry.path(16), height: geometry.path(16))
        .overlay(Circle().strokeBorder(Paper.rim, lineWidth: geometry.path(2)))
        .offset(x: geometry.path(12), y: -geometry.path(12))
      Circle()
        .fill(Paper.paper)
        .frame(width: geometry.path(9), height: geometry.path(9))
        .overlay(Circle().strokeBorder(Paper.rim, lineWidth: geometry.path(1.5)))
    }
    .frame(
      width: geometry.path(Self.width), height: geometry.path(Self.height),
      alignment: .bottomLeading
    )
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}

#Preview {
  ZStack {
    Color(hex: 0x8FCB6B)
    ThoughtBubble(art: "cast-nest", geometry: ReadingGeometry(size: Metrics.phone.reference))
  }
  .frame(width: 240, height: 160)
}
