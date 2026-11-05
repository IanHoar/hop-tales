import ComposableArchitecture
import Content
import DesignSystem
import SwiftUI
import World

struct PathScene: View {
  let path: WordPath
  let position: HopTarget
  let cameraX: CGFloat
  let pose: HareMotion.Pose
  let friend: Friend
  let look: String?
  let lift: CGFloat
  let title: String
  let bigWords: Set<WordRef>
  let soundButtons: Bool
  let treat: StoryTreat?
  let tint: Color
  let sentences: [Sentence]
  let cues: [PropKey: PropCue]
  let now: Date?
  var cheer: TimeInterval?
  let isSpeaking: Bool
  let label: String
  let tip: HopTarget?
  let explain: (HopTarget) -> Void
  let tap: () -> Void

  private var geometry: ReadingGeometry { path.geometry }

  var body: some View {
    ZStack {
      sign(at: path.startSign) {
        signText(title, size: 17)
      }
      sign(at: path.endSign) {
        signText("The end", size: 21)
      }
      StoryPropLayer(
        path: path, sentences: sentences, position: position, cameraX: cameraX, cues: cues,
        now: now, tint: tint, world: friend
      )
      ForEach(visibleStops, id: \.target) { stop in
        PathWord(
          text: stop.text,
          leading: stop.leading,
          trailing: stop.trailing,
          state: WordPath.state(of: stop.target, at: position),
          size: path.wordSize,
          overhang: geometry.path(14),
          isBig: bigWords.contains(WordRef(sentence: stop.target.sentence, word: stop.target.word)),
          isPulsing: isSpeaking && stop.target == position,
          soundButtons: soundButtons,
          chalk: path.style.chalk
        )
        .scaleEffect(stop.target == path.stops.last?.target ? FinishCheer.wordScale(at: cheer) : 1)
        .position(
          x: stop.centre - cameraX + path.lastWordShift(of: stop, cameraX: cameraX),
          y: path.wordY
        )
      }
      treatOnPath
      hare
      challengeTargets
      currentWordTarget
      challengeTip
    }
    .frame(width: geometry.size.width, height: geometry.size.height)
  }

  @ViewBuilder
  private var treatOnPath: some View {
    if let treat, let next = treatStop(treat) {
      TreatSticker(friend: treat.friend, height: geometry.path(44))
        .colorMultiply(tint)
        .animation(.easeInOut(duration: MeadowScene.moodCrossfade), value: tint)
        .rotationEffect(.degrees(-24))
        .position(
          x: next.centre - cameraX - geometry.path(WordPath.treatBeforeWord),
          y: path.hareFeetY + geometry.path(4)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
  }

  private func treatStop(_ treat: StoryTreat) -> WordPath.Stop? {
    guard (position.sentence, position.word) <= (treat.word.sentence, treat.word.word) else {
      return nil
    }
    return path.stop(at: HopTarget(sentence: treat.word.sentence, word: treat.word.word + 1))
  }

  private var visibleStops: [WordPath.Stop] {
    let margin = geometry.path(200)
    return path.stops.filter {
      let x = $0.centre - cameraX
      return x > -margin && x < geometry.size.width + margin
    }
  }

  private func sign<Label: View>(
    at x: CGFloat,
    @ViewBuilder label: () -> Label
  ) -> some View {
    Signpost(height: path.signHeight, label: label)
      .colorMultiply(tint)
      .animation(.easeInOut(duration: MeadowScene.moodCrossfade), value: tint)
      .position(x: x - cameraX, y: path.signFeetY - path.signHeight / 2)
      .allowsHitTesting(false)
      .accessibilityHidden(true)
  }

  private func signText(_ text: String, size: CGFloat) -> some View {
    Text(text)
      .font(Typography.display(geometry.path(size)))
      .foregroundStyle(Color(hex: 0x3B2A20))
      .multilineTextAlignment(.center)
      .lineLimit(2)
      .minimumScaleFactor(0.6)
      .rotationEffect(.degrees(-1.5))
      .blendMode(.multiply)
  }

  private var hare: some View {
    let hopping = pose.frame.sheet == .hop
    let airborne = hopping && (2...5).contains(pose.frame.index)
    return ZStack {
      Ellipse()
        .fill(
          RadialGradient(
            colors: [Paper.shadow.opacity(1.6), .clear],
            center: .center,
            startRadius: 0,
            endRadius: geometry.path(40)
          )
        )
        .frame(width: geometry.path(airborne ? 52 : 80), height: geometry.path(14))
        .opacity(airborne ? 0.45 : 1)
        .position(x: path.hareX, y: path.hareFeetY)
      HareSprite(
        HareFrame(pose.frame.sheet, pose.frame.index, friend: friend, look: look),
        height: path.hareHeight(hopping: hopping)
      )
        .scaleEffect(x: pose.scaleX, y: pose.scaleY, anchor: .center)
        .position(x: path.hareX, y: path.hareFeetY - lift)
    }
    .transaction { $0.animation = nil }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

}
