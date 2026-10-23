import DesignSystem
import SwiftUI

struct StickerButton<Art: View>: View {
  let title: String
  @ViewBuilder let art: () -> Art
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 6) {
        art()
          .frame(width: 84, height: 84)
          .background(Paper.rim.opacity(0.7), in: Circle())
          .overlay(Circle().strokeBorder(Paper.rim, lineWidth: 3))
          .shadow(color: Paper.shadow.opacity(0.6), radius: 4, y: 3)
        Text(title)
          .font(Typography.display(16))
          .foregroundStyle(Paper.ink)
      }
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
  }
}
