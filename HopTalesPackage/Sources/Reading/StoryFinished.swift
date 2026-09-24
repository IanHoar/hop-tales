import DesignSystem
import SwiftUI

struct StoryFinished: View {
  static let stickerY: CGFloat = 752

  let title: String
  let stars: Int
  let geometry: ReadingGeometry
  let readAgain: () -> Void

  var body: some View {
    HStack(spacing: geometry.path(12)) {
      Button(action: readAgain) {
        HStack(spacing: geometry.path(8)) {
          Image(systemName: "arrow.clockwise")
            .font(.system(size: geometry.path(15), weight: .heavy))
          Text("Read it again")
            .font(Typography.display(geometry.path(18)))
        }
        .foregroundStyle(Paper.ink)
        .padding(.horizontal, geometry.path(18))
        .frame(height: geometry.path(48))
        .paperChip(Capsule(), rim: geometry.path(4))
      }
      .buttonStyle(.plain)
      HStack(spacing: geometry.path(6)) {
        PaperStar(size: geometry.path(20))
        Text("+\(stars)")
          .font(Typography.display(geometry.path(18)))
          .foregroundStyle(Paper.ink)
          .monospacedDigit()
      }
      .padding(.horizontal, geometry.path(14))
      .frame(height: geometry.path(44))
      .paperChip(Capsule(), rim: geometry.path(4))
      .rotationEffect(.degrees(4))
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("\(stars) stars")
    }
    .position(x: geometry.size.width / 2, y: geometry.y(Self.stickerY))
    .accessibilityElement(children: .contain)
    .accessibilityLabel("You finished \(title).")
  }
}

#if DEBUG
struct StoryFinishedPreview: View {
  var body: some View {
    ZStack {
      Paper.sage
      StoryFinished(
        title: "The Meadow Walk",
        stars: 86,
        geometry: ReadingGeometry(size: Metrics.phone.reference)
      ) {}
    }
    .frame(width: Metrics.phone.reference.width, height: Metrics.phone.reference.height)
  }
}

#Preview { StoryFinishedPreview() }
#endif
