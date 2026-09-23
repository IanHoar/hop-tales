import DesignSystem
import SwiftUI
import World

public struct TVWaitingScreen: View {
  let childName: String?

  public init(childName: String?) {
    self.childName = childName
  }

  public var body: some View {
    ZStack {
      TVWorld(progress: 0)
      VStack(spacing: 18) {
        Text("Hop Tales")
          .font(Typography.ui(96))
          .foregroundStyle(Palette.ink)
        Text(childName.map { "Pick a story on the phone, \($0)" } ?? "Pick a story on the phone")
          .font(Typography.ui(40))
          .foregroundStyle(Palette.chipText)
      }
      .padding(.horizontal, 72)
      .padding(.vertical, 48)
      .background(Palette.cream.opacity(0.92), in: .rect(cornerRadius: 56, style: .continuous))
    }
    .accessibilityHidden(true)
  }
}

struct TVWorld: View {
  let progress: Double
  @Environment(\.freezesMotion) private var freezesMotion

  var body: some View {
    Group {
      if freezesMotion {
        Color(hex: 0x8FCB6B)
      } else {
        WorldView(progress: progress)
      }
    }
    .ignoresSafeArea()
  }
}
