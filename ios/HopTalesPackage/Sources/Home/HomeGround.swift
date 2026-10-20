import Content
import DesignSystem
import SwiftUI
import World

struct HomeGround: View {
  let world: Friend
  let mood: Mood
  let tileWidth: CGFloat

  var body: some View {
    ZStack(alignment: .bottom) {
      Self.gradient(WorldStyle.of(world), tint: mood.landTint)
      MeadowUnderstory(world: world, mood: mood, tileWidth: tileWidth)
        .padding(.top, -MeadowUnderstory.overlap(tileWidth: tileWidth))
    }
    .accessibilityHidden(true)
  }

  static func gradient(_ style: WorldStyle, tint: UIColor) -> LinearGradient {
    LinearGradient(
      colors: [style.ground, 0xD9D6A6, 0xEDE6C8].map { multiply($0, by: tint) },
      startPoint: .top,
      endPoint: .bottom
    )
  }

  static func multiply(_ hex: UInt32, by tint: UIColor) -> Color {
    var red: CGFloat = 1, green: CGFloat = 1, blue: CGFloat = 1, alpha: CGFloat = 1
    tint.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return Color(
      red: Double((hex >> 16) & 0xFF) / 255 * red,
      green: Double((hex >> 8) & 0xFF) / 255 * green,
      blue: Double(hex & 0xFF) / 255 * blue
    )
  }
}
