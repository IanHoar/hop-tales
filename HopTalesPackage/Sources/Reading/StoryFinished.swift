import DesignSystem
import SwiftUI

struct StoryFinished: View {
  let title: String
  let stars: Int
  let action: () -> Void

  var body: some View {
    ZStack {
      Palette.duskRoot.opacity(0.55)
        .ignoresSafeArea()
      VStack(spacing: 20) {
        ZStack {
          ForEach(0..<3, id: \.self) { index in
            Star()
              .fill(Palette.amber)
              .frame(width: index == 1 ? 58 : 42, height: index == 1 ? 58 : 42)
              .offset(x: CGFloat(index - 1) * 52, y: index == 1 ? -8 : 6)
          }
        }
        .frame(height: 70)
        Text("You finished")
          .font(Typography.ui(16))
          .foregroundStyle(Palette.muted)
        Text(title)
          .font(Typography.ui(28))
          .foregroundStyle(Palette.ink)
          .multilineTextAlignment(.center)
        Text("\(stars) stars")
          .font(Typography.ui(20))
          .foregroundStyle(Palette.starText)
        Button(action: action) {
          Text("Back to stories")
            .font(Typography.ui(17))
            .foregroundStyle(Palette.cream)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(Palette.ink, in: .capsule)
        }
        .padding(.top, 4)
      }
      .padding(28)
      .frame(maxWidth: 330)
      .background {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
          .fill(Palette.cream)
          .shadow(color: Palette.ink.opacity(0.3), radius: 30, x: 0, y: 16)
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("You finished \(title). \(stars) stars.")
  }
}

#if DEBUG
struct StoryFinishedPreview: View {
  var body: some View {
    ZStack {
      Color(hex: 0x8FCB6B)
      StoryFinished(title: "The castle road", stars: 86) {}
    }
    .frame(width: Metrics.phone.reference.width, height: Metrics.phone.reference.height)
  }
}

#Preview { StoryFinishedPreview() }
#endif
