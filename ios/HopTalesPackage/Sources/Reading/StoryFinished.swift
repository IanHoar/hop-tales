import DesignSystem
import SwiftUI

struct StoryFinished: View {
  static let stickerY: CGFloat = 752

  let title: String
  let stars: Int
  let geometry: ReadingGeometry
  var leadsHome = true
  var finishedAt: Date?
  @Environment(\.freezesMotion) private var freezesMotion
  var countsUp = true
  var onStarChip: (CGPoint) -> Void = { _ in }
  let readAgain: () -> Void
  let done: () -> Void

  var body: some View {
    VStack(spacing: geometry.path(14)) {
      HStack(spacing: geometry.path(12)) {
        readAgainButton
        starChip
      }
      if leadsHome {
        doneButton
      } else {
        Color.clear.frame(height: geometry.path(56))
      }
    }
    .position(x: geometry.size.width / 2, y: geometry.y(Self.stickerY - 24))
    .accessibilityElement(children: .contain)
    .accessibilityLabel("You finished \(title).")
  }

  private var doneButton: some View {
    Button(action: done) {
      Text("Back to my stories")
        .font(Typography.display(geometry.path(21)))
        .foregroundStyle(Paper.onRed)
        .lineLimit(1)
        .padding(.horizontal, geometry.path(26))
        .frame(minWidth: geometry.path(236))
        .frame(height: geometry.path(56))
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

  private var cheerStart: Date? { freezesMotion ? nil : finishedAt }

  private var starChip: some View {
    TimelineView(.animation(paused: cheerStart == nil)) { context in
      let elapsed = cheerStart.map { context.date.timeIntervalSince($0) }
      starChipBody(shown: countsUp ? FinishCheer.shownStars(stars, at: elapsed) : stars)
        .scaleEffect(FinishCheer.chipScale(at: elapsed))
    }
    .onGeometryChange(for: CGPoint.self) { proxy in
      let frame = proxy.frame(in: .named(FinishCheer.space))
      return CGPoint(x: frame.midX, y: frame.midY)
    } action: { centre in
      onStarChip(centre)
    }
  }

  private func starChipBody(shown: Int) -> some View {
    HStack(spacing: geometry.path(6)) {
      PaperStar(size: geometry.path(20))
      Text("+\(shown)")
        .font(Typography.display(geometry.path(18)))
        .foregroundStyle(Paper.ink)
        .monospacedDigit()
        .contentTransition(.numericText(value: Double(shown)))
        .animation(.snappy(duration: 0.2), value: shown)
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
