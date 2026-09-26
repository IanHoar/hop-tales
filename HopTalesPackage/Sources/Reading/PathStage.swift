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
  @State private var pickup: StoryTreat?
  @State private var pickupLanded = false
  @State private var showsBasket = false
  @State private var clock = HopClock()
  @State private var paths = PathCache()
  @State private var cues: [PropKey: PropCue] = [:]
  @State private var tip: ChallengeTipState?

  private var position: HopTarget {
    HopTarget(sentence: store.sentenceIndex, word: store.wordIndex)
  }

  private var isStill: Bool { reduceMotion || freezesMotion }

  var body: some View {
    let path = paths.path(for: store.story, friend: store.friend, geometry: geometry)
    let camera = camera ?? MeadowCamera(at: path.camera(at: position))
    ZStack {
      backdrop(camera)
      if freezesMotion {
        scene(path, cameraX: camera.to, pose: .resting, lift: 0, now: nil)
      } else if reduceMotion {
        ZStack {
          scene(path, cameraX: camera.to, pose: .resting, lift: 0, now: nil)
            .id(position)
            .transition(.opacity)
        }
        .animation(MeadowBackdrop.stillCrossfade, value: position)
      } else {
        TimelineView(.animation) { context in
          let now = clock.time(at: MeadowCamera.now)
          scene(
            path,
            cameraX: camera.x(at: now),
            pose: motion.pose(at: now, reduceMotion: false),
            lift: motion.arc(at: now) * path.apex(carried: motion.hop?.carried ?? false)
              * (bigHop ? WordPath.bigWordLift : 1),
            now: context.date
          )
        }
      }
      pickupLayer
      if case let .story(stars) = store.completed {
        StoryFinished(
          title: store.story.title,
          stars: stars,
          geometry: geometry,
          readAgain: { store.send(.readAgainTapped) },
          done: { store.send(.backToStoriesTapped) }
        )
        .transition(.opacity.animation(.easeOut(duration: 0.4).delay(WordPath.pan)))
        journeyPanel
          .transition(.opacity.animation(.easeOut(duration: 0.4).delay(WordPath.pan)))
      }
    }
    .frame(width: geometry.size.width, height: geometry.size.height)
    .animation(Motion.recognised, value: store.completed)
    .onChange(of: position) { old, new in
      advance(from: old, to: new, on: path)
      cue(from: old, to: new)
    }
    .onAppear { cue(from: position, to: position) }
    .onChange(of: geometry) { self.camera = nil }
  }

  private func pickUp(_ treat: StoryTreat) {
    pickup = treat
    pickupLanded = false
    Task { @MainActor in
      try? await Task.sleep(for: .seconds(WordPath.pickupDelay))
      withAnimation(.spring(duration: 0.6, bounce: 0.25)) { pickupLanded = true }
      withAnimation(.easeOut(duration: 0.2).delay(0.5)) { showsBasket = true }
      try? await Task.sleep(for: .seconds(0.6 + WordPath.basketHold))
      withAnimation(.easeIn(duration: 0.4)) {
        showsBasket = false
        pickup = nil
      }
    }
  }

  @ViewBuilder
  private var pickupLayer: some View {
    let chip = CGPoint(x: geometry.size.width - geometry.path(92), y: geometry.y(96))
    ZStack {
      if let pickup, !isStill {
        let start = CGPoint(
          x: geometry.path(WordPath.hareX + 12),
          y: geometry.pathCentre + geometry.path(WordPath.hareFeetBelowPath + 4)
        )
        TreatSticker(friend: pickup.friend, height: geometry.path(44))
          .rotationEffect(.degrees(pickupLanded ? 0 : -24))
          .scaleEffect(pickupLanded ? 0.6 : 1)
          .opacity(pickupLanded ? 0 : 1)
          .position(pickupLanded ? chip : start)
      }
      if showsBasket, let treat = store.treat {
        HStack(spacing: geometry.path(6)) {
          if treat.isTrail {
            FriendSticker(treat.friend, height: geometry.path(28), isSilhouette: true)
              .opacity(0.6)
          } else {
            Sticker("collect-basket", height: geometry.path(28))
          }
          TreatSticker(friend: treat.friend, height: geometry.path(22))
          Text("+1")
            .font(Typography.display(geometry.path(16)))
            .foregroundStyle(Paper.ink)
        }
        .padding(.horizontal, geometry.path(12))
        .frame(height: geometry.path(42))
        .paperChip(Capsule(), rim: geometry.path(3))
        .position(chip)
        .transition(.scale(scale: 0.8).combined(with: .opacity))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("You found a \(treat.friend.treat.one).")
      }
    }
    .frame(width: geometry.size.width, height: geometry.size.height)
    .allowsHitTesting(false)
  }

  @ViewBuilder
  private var journeyPanel: some View {
    VStack {
      if let callout = store.callout {
        CalloutCard(moment: callout, geometry: geometry, isDone: store.hasTriedItOn) {
          if let story = callout.story { store.send(.continueTapped(story)) }
          if case let .basketFull(friend, _) = callout { store.send(.tryItOnTapped(friend)) }
        } dismiss: {
          store.send(.momentDismissed)
        }
        .id(String(describing: callout))
        .transition(.scale(scale: 0.9).combined(with: .opacity))
      } else if case let .tally(steps, total, goal, bigWords, next) = store.tally {
        TallyCard(
          steps: steps, total: total, goal: goal, bigWords: bigWords, next: next,
          treat: store.collectedTreat?.treat, trail: store.collectedTreat?.trail ?? 0,
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
      framing: .path(scale: geometry.pathScale, centre: geometry.pathCentre),
      world: store.friend
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
    lift: CGFloat,
    now: Date?
  ) -> some View {
    PathScene(
      path: path,
      position: position,
      cameraX: cameraX,
      pose: pose,
      friend: store.friend,
      look: store.look,
      lift: lift,
      title: store.story.title,
      bigWords: store.bigWords,
      treat: store.treat,
      waiting: store.callout?.waitingFriend,
      tint: Color(uiColor: store.mood.landTint),
      sentences: store.story.sentences,
      cues: cues,
      now: now,
      isSpeaking: store.isSpeaking,
      label: store.wordCardLabel,
      tip: tip?.target,
      explain: { target in explain(target) },
      tap: { store.send(.currentWordTapped) }
    )
  }

  private func explain(_ target: HopTarget) {
    let shown = ChallengeTipState(target: target)
    withAnimation(.easeOut(duration: 0.2)) { tip = shown }
    Task { @MainActor in
      try? await Task.sleep(for: ChallengeTip.hold)
      guard tip == shown else { return }
      withAnimation(.easeIn(duration: 0.3)) { tip = nil }
    }
  }

  private func cue(from old: HopTarget, to new: HopTarget) {
    let backward = (new.sentence, new.word) < (old.sentence, old.word)
    cues = PropTiming.cues(backward ? [:] : cues, story: store.story, at: new, now: .now)
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
    if let treat = store.treat, treat.word == WordRef(sentence: old.sentence, word: old.word) {
      pickUp(treat)
    }
    clock.began(at: now)
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
  let friend: Friend
  let look: String?
  let lift: CGFloat
  let title: String
  let bigWords: Set<WordRef>
  let treat: StoryTreat?
  let waiting: Friend?
  let tint: Color
  let sentences: [Sentence]
  let cues: [PropKey: PropCue]
  let now: Date?
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
          chalk: path.style.chalk
        )
        .position(x: stop.centre - cameraX, y: path.wordY)
      }
      treatOnPath
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
