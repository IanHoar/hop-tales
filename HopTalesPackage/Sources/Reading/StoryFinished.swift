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
              .fill(Palette.gold)
              .overlay(Star().stroke(Palette.outline, lineWidth: 3))
              .frame(width: index == 1 ? 58 : 42, height: index == 1 ? 58 : 42)
              .offset(x: CGFloat(index - 1) * 52, y: index == 1 ? -8 : 6)
          }
        }
        .frame(height: 70)
        Text("You finished")
          .font(Typography.ui(16))
          .foregroundStyle(Palette.muted)
        Text(title)
          .font(Typography.display(30))
          .foregroundStyle(Palette.ink)
          .multilineTextAlignment(.center)
        CoinChip(count: stars, height: 46)
        Button(action: action) {
          Text("Back to stories")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.ink(.primary))
        .padding(.top, 4)
      }
      .padding(28)
      .frame(maxWidth: 330)
      .bevel(
        Palette.parchment,
        lip: Palette.parchmentLip,
        shape: RoundedRectangle(cornerRadius: 32, style: .continuous),
        border: 4,
        drop: 6,
        lipHeight: 9
      )
      .shadow(color: Color(hex: 0x0C0A1E, opacity: 0.32), radius: 17, x: 0, y: 22)
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
