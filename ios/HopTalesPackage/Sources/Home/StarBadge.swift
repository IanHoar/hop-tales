import DesignSystem
import SwiftUI

struct StarBadge: View {
  let size: CGFloat

  var body: some View {
    Star()
      .fill(Paper.wash)
      .overlay(Star().stroke(Paper.washRing, lineWidth: max(1, size * 0.07)))
      .frame(width: size, height: size)
  }
}
