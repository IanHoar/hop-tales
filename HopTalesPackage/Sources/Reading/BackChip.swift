import DesignSystem
import SwiftUI

struct BackChip: View {
  let geometry: ReadingGeometry
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: "chevron.left")
        .font(.system(size: geometry.path(16), weight: .heavy))
        .foregroundStyle(Paper.ink)
        .frame(width: geometry.path(38), height: geometry.path(38))
        .background(Paper.paper.opacity(0.72), in: Circle())
        .overlay(Circle().strokeBorder(Paper.rim, lineWidth: geometry.path(3)))
        .compositingGroup()
        .shadow(color: Paper.shadow, radius: geometry.path(4), y: geometry.path(2))
        .frame(width: geometry.path(44), height: geometry.path(44))
        .contentShape(.rect)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Back to stories")
  }
}
