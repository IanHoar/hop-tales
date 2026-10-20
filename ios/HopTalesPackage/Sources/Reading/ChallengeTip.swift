import Content
import DesignSystem
import SwiftUI

struct ChallengeTipState: Equatable {
  let target: HopTarget
  let id = UUID()
}

struct ChallengeTip: View {
  static let hold = Duration.seconds(4)
  static let title = "Challenge word"
  static let detail = "A word from a level or two ahead, worth 5 steps instead of 1."
  static let hint = "Double tap to hear the word. \(title): \(detail)"

  let geometry: ReadingGeometry

  var body: some View {
    VStack(alignment: .leading, spacing: geometry.path(4)) {
      Label(Self.title, systemImage: "star.fill")
        .font(Typography.display(geometry.path(17)))
        .foregroundStyle(Paper.ink)
        .labelStyle(TipLabelStyle(geometry: geometry))
      Text(Self.detail)
        .font(Typography.ui(geometry.path(14), weight: .medium))
        .foregroundStyle(Paper.ink.opacity(0.85))
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.horizontal, geometry.path(14))
    .padding(.vertical, geometry.path(10))
    .frame(width: geometry.path(250), alignment: .leading)
    .paperChip(RoundedRectangle(cornerRadius: geometry.path(16)), rim: geometry.path(3))
    .accessibilityElement(children: .combine)
  }
}

struct TipLabelStyle: LabelStyle {
  let geometry: ReadingGeometry

  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: geometry.path(6)) {
      configuration.icon
        .font(.system(size: geometry.path(13), weight: .bold))
        .foregroundStyle(Palette.gold)
      configuration.title
    }
  }
}

extension PathScene {
  @ViewBuilder
  var currentWordTarget: some View {
    if let stop = path.stop(at: position) {
      let minimum = path.geometry.path(44)
      Color.clear
        .frame(width: max(minimum, stop.width), height: max(minimum, path.wordHeight))
        .contentShape(.rect)
        .position(x: stop.centre - cameraX, y: path.wordY)
        .gesture(wordGesture(at: position))
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityHint(
          isChallenge(position) ? ChallengeTip.hint : "Double tap to hear the word."
        )
        .accessibilityAddTraits(.startsMediaSession)
        .accessibilityAction { tap() }
    }
  }

  func isChallenge(_ target: HopTarget) -> Bool {
    bigWords.contains(WordRef(sentence: target.sentence, word: target.word))
  }

  func wordGesture(at target: HopTarget) -> some Gesture {
    ExclusiveGesture(LongPressGesture(minimumDuration: 0.5), TapGesture())
      .onEnded { value in
        switch value {
        case .first where isChallenge(target): explain(target)
        case .first, .second: tap()
        }
      }
  }

  var challengeTargets: some View {
    let margin = path.geometry.path(200)
    let targets = path.stops.filter { stop in
      let x = stop.centre - cameraX
      return stop.target != position && isChallenge(stop.target)
        && x > -margin && x < path.geometry.size.width + margin
    }
    return ForEach(targets, id: \.target) { stop in
      Color.clear
        .frame(width: max(path.geometry.path(44), stop.width), height: path.wordHeight)
        .contentShape(.rect)
        .position(x: stop.centre - cameraX, y: path.wordY)
        .onTapGesture { explain(stop.target) }
        .accessibilityHidden(true)
    }
  }

  @ViewBuilder
  var challengeTip: some View {
    if let tip, let stop = path.stop(at: tip) {
      let geometry = path.geometry
      let half = geometry.path(125)
      let inset = geometry.path(16)
      let x = min(max(stop.centre - cameraX, half + inset), geometry.size.width - half - inset)
      ChallengeTip(geometry: geometry)
        .position(x: x, y: path.wordY - path.wordHeight - geometry.path(40))
        .transition(.scale(scale: 0.9, anchor: .bottom).combined(with: .opacity))
        .allowsHitTesting(false)
    }
  }
}

#if DEBUG
  struct ChallengeTipPreview: View {
    var body: some View {
      ZStack {
        Paper.sage
        ChallengeTip(geometry: ReadingGeometry(size: Metrics.phone.reference))
      }
      .frame(width: 360, height: 200)
    }
  }

  #Preview { ChallengeTipPreview() }
#endif
