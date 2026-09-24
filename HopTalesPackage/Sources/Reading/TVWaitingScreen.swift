import Content
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
      MeadowBackdrop(progress: 0, mood: Mood(sky: .golden, weather: .clouds))
      VStack(spacing: 18) {
        Text("Hop Tales")
          .font(Typography.display(120))
          .foregroundStyle(Palette.red)
          .inkHalo(9)
        Text(childName.map { "Pick a story on the phone, \($0)" } ?? "Pick a story on the phone")
          .font(Typography.ui(40))
          .foregroundStyle(Palette.ink)
      }
      .padding(.horizontal, 80)
      .padding(.vertical, 56)
      .bevel(
        Palette.parchment,
        lip: Palette.parchmentLip,
        shape: RoundedRectangle(cornerRadius: 56, style: .continuous),
        border: 6,
        drop: 10
      )
    }
    .accessibilityHidden(true)
  }
}
