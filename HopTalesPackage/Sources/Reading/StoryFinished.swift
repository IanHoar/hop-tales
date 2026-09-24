import DesignSystem
import SwiftUI

struct StoryFinished: View {
  let title: String
  let stars: Int
  let action: () -> Void

  var body: some View {
    ZStack {
      Paper.night.opacity(0.45)
        .ignoresSafeArea()
      VStack(spacing: 18) {
        ZStack {
          ForEach(0..<3, id: \.self) { index in
            PaperStar(size: index == 1 ? 58 : 42)
              .offset(x: CGFloat(index - 1) * 52, y: index == 1 ? -8 : 6)
          }
        }
        .frame(height: 70)
        Text("You finished")
          .font(Typography.ui(16))
          .foregroundStyle(Paper.muted)
        Text(title)
          .font(Typography.display(30))
          .foregroundStyle(Paper.ink)
          .multilineTextAlignment(.center)
        HStack(spacing: 8) {
          PaperStar(size: 22)
          Text("\(stars)")
            .font(Typography.display(20))
            .foregroundStyle(Paper.ink)
            .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
        .paperChip(Capsule())
        Button("Back to stories", action: action)
          .buttonStyle(.paper)
          .padding(.top, 6)
      }
      .padding(28)
      .frame(maxWidth: 330)
      .background {
        Deckle(seed: 12, jitter: 3, step: 12)
          .fill(Paper.paper)
          .shadow(color: Paper.shadow, radius: 12, y: 8)
      }
      .rotationEffect(.degrees(-1))
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("You finished \(title). \(stars) stars.")
  }
}

#if DEBUG
struct StoryFinishedPreview: View {
  var body: some View {
    ZStack {
      Paper.sage
      StoryFinished(title: "The Meadow Walk", stars: 86) {}
    }
    .frame(width: Metrics.phone.reference.width, height: Metrics.phone.reference.height)
  }
}

#Preview { StoryFinishedPreview() }
#endif
