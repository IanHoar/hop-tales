import DesignSystem
import SwiftUI

struct StoryFinished: View {
  static let stickerY: CGFloat = 752

  let title: String
  let stars: Int
  let geometry: ReadingGeometry
  let readAgain: () -> Void
  let done: () -> Void

  var body: some View {
    VStack(spacing: geometry.path(14)) {
      HStack(spacing: geometry.path(12)) {
        readAgainButton
        starChip
      }
      doneButton
    }
    .position(x: geometry.size.width / 2, y: geometry.y(Self.stickerY - 24))
    .accessibilityElement(children: .contain)
    .accessibilityLabel("You finished \(title).")
  }

  private var doneButton: some View {
    Button(action: done) {
      Text("Done")
        .font(Typography.display(geometry.path(21)))
        .foregroundStyle(Paper.onRed)
        .frame(width: geometry.path(236), height: geometry.path(56))
        .background {
          Capsule()
            .fill(Paper.rim)
            .shadow(color: Paper.shadow, radius: geometry.path(5), y: geometry.path(4))
          Capsule()
            .fill(Paper.red)
            .padding(geometry.path(4))
        }
    }
    .buttonStyle(PressableButtonStyle())
    .accessibilitySortPriority(1)
  }

  private var readAgainButton: some View {
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
  }

  private var starChip: some View {
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
}

struct PressableButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
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
        geometry: ReadingGeometry(size: Metrics.phone.reference),
        readAgain: {},
        done: {}
      )
    }
    .frame(width: Metrics.phone.reference.width, height: Metrics.phone.reference.height)
  }
}

#Preview { StoryFinishedPreview() }
#endif
