import ComposableArchitecture2
import Content
import DesignSystem
import SwiftUI
import World

struct PathStage: View {
  let store: StoreOf<Reading>
  let geometry: ReadingGeometry
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.freezesMotion) private var freezesMotion
  @State private var camera: MeadowCamera?
  @State private var motion = HareMotion()
  @State private var bigHop = false

  private var position: HopTarget {
    HopTarget(sentence: store.sentenceIndex, word: store.wordIndex)
  }

  private var isStill: Bool { reduceMotion || freezesMotion }

  var body: some View {
    let path = WordPath(sentences: store.story.sentences.map(\.words), geometry: geometry)
    let camera = camera ?? MeadowCamera(at: path.camera(at: position))
    ZStack {
      backdrop(camera)
      if freezesMotion {
        scene(path, cameraX: camera.to, pose: .resting, lift: 0)
      } else if reduceMotion {
        ZStack {
          scene(path, cameraX: camera.to, pose: .resting, lift: 0)
            .id(position)
            .transition(.opacity)
        }
        .animation(MeadowBackdrop.stillCrossfade, value: position)
      } else {
        TimelineView(.animation) { _ in
          let now = MeadowCamera.now
          scene(
            path,
            cameraX: camera.x(at: now),
            pose: motion.pose(at: now, reduceMotion: false),
            lift: motion.arc(at: now) * path.apex(carried: motion.hop?.carried ?? false)
              * (bigHop ? WordPath.bigWordLift : 1)
          )
        }
      }
      if case let .story(stars) = store.completed {
        StoryFinished(title: store.story.title, stars: stars, geometry: geometry) {
          store.send(.readAgainTapped)
        }
        .transition(.opacity.animation(.easeOut(duration: 0.4).delay(WordPath.pan)))
        journeyPanel
          .transition(.opacity.animation(.easeOut(duration: 0.4).delay(WordPath.pan)))
      }
    }
    .frame(width: geometry.size.width, height: geometry.size.height)
    .animation(Motion.recognised, value: store.completed)
    .onChange(of: position) { old, new in advance(from: old, to: new, on: path) }
    .onChange(of: geometry) { self.camera = nil }
  }

  @ViewBuilder
  private var journeyPanel: some View {
    VStack {
      if let callout = store.callout {
        CalloutCard(moment: callout, geometry: geometry) {
          if let story = callout.story { store.send(.continueTapped(story)) }
        } dismiss: {
          store.send(.momentDismissed)
        }
        .id(String(describing: callout))
        .transition(.scale(scale: 0.9).combined(with: .opacity))
      } else if case let .tally(steps, total, goal, bigWords, next) = store.tally {
        TallyCard(
          steps: steps, total: total, goal: goal, bigWords: bigWords, next: next,
          geometry: geometry
        )
        .transition(.opacity)
      }
      Spacer()
    }
    .padding(.top, geometry.y(110))
    .frame(width: geometry.size.width, height: geometry.size.height)
    .overlay {
      if case .newFriend = store.callout { PaperConfetti(size: geometry.size) }
    }
    .animation(.easeInOut(duration: 0.3), value: store.journeyMoments)
  }

  @ViewBuilder
  private func backdrop(_ camera: MeadowCamera) -> some View {
    let world = MeadowBackdrop(
      camera: camera,
      mood: store.mood,
      framing: .path(scale: geometry.pathScale, centre: geometry.pathCentre)
    )
    #if DEBUG
      world.modifier(DebugTapToAdvance(store: store))
    #else
      world
    #endif
  }

  private func scene(
    _ path: WordPath,
    cameraX: CGFloat,
    pose: HareMotion.Pose,
    lift: CGFloat
  ) -> some View {
    PathScene(
      path: path,
      position: position,
      cameraX: cameraX,
      pose: pose,
      lift: lift,
      title: store.story.title,
      bigWords: store.bigWords,
      waiting: store.callout?.waitingFriend,
      tint: Color(uiColor: store.mood.landTint),
      isSpeaking: store.isSpeaking,
      label: store.wordCardLabel
    ) {
      store.send(.currentWordTapped)
    }
  }

  private func advance(from old: HopTarget, to new: HopTarget, on path: WordPath) {
    let target = path.camera(at: new)
    let forward = (new.sentence, new.word) > (old.sentence, old.word)
    guard !isStill, forward else {
      camera = MeadowCamera(at: target)
      return
    }
    let now = MeadowCamera.now
    bigHop = store.bigWords.contains(WordRef(sentence: old.sentence, word: old.word))
    motion.jump(at: now, distance: 0, carried: new.sentence != old.sentence)
    let rate = motion.hop?.rate ?? 1
    let current = camera ?? MeadowCamera(at: path.camera(at: old))
    camera = current.panning(to: target, at: now, over: WordPath.pan / rate)
  }
}

struct PathScene: View {
  let path: WordPath
  let position: HopTarget
  let cameraX: CGFloat
  let pose: HareMotion.Pose
  let lift: CGFloat
  let title: String
  let bigWords: Set<WordRef>
  let waiting: Friend?
  let tint: Color
  let isSpeaking: Bool
  let label: String
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
      ForEach(visibleStops, id: \.target) { stop in
        PathWord(
          text: stop.text,
          state: WordPath.state(of: stop.target, at: position),
          size: path.wordSize,
          overhang: geometry.path(14),
          isBig: bigWords.contains(WordRef(sentence: stop.target.sentence, word: stop.target.word)),
          isPulsing: isSpeaking && stop.target == position
        )
        .position(x: stop.centre - cameraX, y: path.wordY)
      }
      if let waiting {
        FriendSticker(waiting, height: path.hareHeight(hopping: false) * 0.78)
          .position(
            x: path.endSign - cameraX - geometry.path(72),
            y: path.hareFeetY - path.hareHeight(hopping: false) * 0.39
          )
          .allowsHitTesting(false)
          .accessibilityHidden(true)
      }
      hare
      currentWordTarget
    }
    .frame(width: geometry.size.width, height: geometry.size.height)
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
      HareSprite(pose.frame, height: path.hareHeight(hopping: hopping))
        .scaleEffect(x: pose.scaleX, y: pose.scaleY, anchor: .center)
        .position(x: path.hareX, y: path.hareFeetY - lift)
    }
    .transaction { $0.animation = nil }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  @ViewBuilder
  private var currentWordTarget: some View {
    if let stop = path.stop(at: position) {
      let minimum = geometry.path(44)
      Color.clear
        .frame(width: max(minimum, stop.width), height: max(minimum, path.wordHeight))
        .contentShape(.rect)
        .position(x: stop.centre - cameraX, y: path.wordY)
        .onTapGesture(perform: tap)
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityHint("Double tap to hear the word.")
        .accessibilityAddTraits(.startsMediaSession)
        .accessibilityAction { tap() }
    }
  }
}

struct PathWord: View {
  @Environment(\.freezesMotion) private var freezesMotion
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var popped = false
  @State private var floated = false
  let text: String
  let state: PathWordState
  let size: CGFloat
  let overhang: CGFloat
  var isBig = false
  var isPulsing = false

  var body: some View {
    Text(text)
      .font(Typography.word(size))
      .foregroundStyle(state.ink)
      .lineLimit(1)
      .fixedSize()
      .background {
        PathWash()
          .padding(.horizontal, -overhang)
          .opacity(state == .read ? 1 : 0)
          .animation(.easeOut(duration: 0.35).delay(0.25), value: state == .read)
      }
      .overlay(alignment: .bottom) {
        if isBig { underline }
      }
      .overlay(alignment: .top) {
        if isBig { star }
      }
      .scaleEffect(scale)
      .animation(.easeInOut(duration: 0.3), value: state)
      .animation(.easeInOut(duration: 0.28).repeatCount(3, autoreverses: true), value: isPulsing)
      .rotation3DEffect(
        .degrees(freezesMotion ? 0 : 24),
        axis: (x: 1, y: 0, z: 0),
        anchor: UnitPoint(x: 0.5, y: 0.6),
        perspective: 0.5
      )
      .blendMode(.multiply)
      .allowsHitTesting(false)
      .accessibilityHidden(true)
      .onChange(of: state) { _, state in
        guard isBig, state == .read, !reduceMotion else { return }
        withAnimation(.easeOut(duration: 0.3)) { popped = true }
        withAnimation(.easeOut(duration: 0.9).delay(0.1)) { floated = true }
      }
  }

  private var underline: some View {
    let solid = state == .read && reduceMotion
    return Capsule()
      .stroke(
        PathWash.gold,
        style: StrokeStyle(
          lineWidth: size * 0.07, lineCap: .round, dash: solid ? [] : [1, size * 0.16]
        )
      )
      .frame(height: size * 0.07)
      .padding(.horizontal, size * 0.05)
      .offset(y: -size * 0.12)
  }

  @ViewBuilder
  private var star: some View {
    let read = state == .read
    ZStack {
      if !read || popped {
        Sticker("collect-star", height: size * 0.42)
          .scaleEffect(popped ? 0 : read ? 1.4 : 1)
          .opacity(popped ? 0 : 1)
      }
      if popped {
        Text("+5")
          .font(Typography.display(size * 0.4))
          .foregroundStyle(Paper.ink)
          .offset(y: floated ? -size * 0.9 : -size * 0.2)
          .opacity(floated ? 0 : 1)
      }
    }
    .offset(y: -size * 0.5)
  }

  private var scale: CGFloat {
    let big = isBig ? WordPath.bigWordScale : 1
    guard state == .current else { return WordPath.sideScale * big }
    return (isPulsing ? 1.08 : 1) * big
  }
}

struct PathWash: View {
  static let gold = Color(hex: 0xF7D774)

  var body: some View {
    Rectangle()
      .fill(
        EllipticalGradient(
          stops: [
            .init(color: Self.gold.opacity(0.95), location: 0),
            .init(color: Self.gold.opacity(0.7), location: 0.52),
            .init(color: Self.gold.opacity(0), location: 0.72)
          ],
          center: .center,
          startRadiusFraction: 0,
          endRadiusFraction: 0.5 * 2.squareRoot()
        )
      )
  }
}
