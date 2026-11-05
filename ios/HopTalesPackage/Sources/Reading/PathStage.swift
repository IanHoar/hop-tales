import ComposableArchitecture
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
  @State private var finishedAt: Date?

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
        FinishedLayer(
          store: store,
          stars: stars,
          geometry: geometry,
          finishedAt: finishedAt,
          lastWord: path.stops.last.map { CGPoint(x: path.lastWordX($0), y: path.wordY) },
          isStill: isStill
        )
        journeyPanel
          .transition(.opacity.animation(.easeOut(duration: 0.4).delay(WordPath.pan)))
      }
    }
    .frame(width: geometry.size.width, height: geometry.size.height)
    .coordinateSpace(.named(FinishCheer.space))
    .animation(Motion.recognised, value: store.completed)
    .onChange(of: store.completed, initial: true) { _, completed in
      guard case .story = completed else { return finishedAt = nil }
      finishedAt = finishedAt ?? Date()
    }
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
      if case .levelOneFinished = store.callout {
        LevelOneCard(geometry: geometry) {
          store.send(.backToMyStoriesTapped)
        }
        .transition(.scale(scale: 0.9).combined(with: .opacity))
      } else if let callout = store.callout {
        CalloutCard(
          moment: callout, geometry: geometry, isDone: store.hasTriedItOn,
          isLast: store.isLastCallout
        ) {
          store.send(.calloutPrimaryTapped)
        } dismiss: {
          store.send(.momentDismissed)
        }
        .id(String(describing: callout))
        .transition(.scale(scale: 0.9).combined(with: .opacity))
      } else if case let .tally(steps, total, goal, bigWords, next, storiesLeft) = store.tally {
        TallyCard(
          steps: steps, total: total, goal: goal, bigWords: bigWords, next: next,
          storiesLeft: storiesLeft,
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
      if case .newFriend = store.callout { PaperConfetti(size: geometry.size, delay: 1.3) }
      if case .levelOneFinished = store.callout { PaperConfetti(size: geometry.size, delay: 0.3) }
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
      soundButtons: store.soundButtons,
      treat: store.treat,
      tint: Color(uiColor: store.mood.landTint),
      sentences: store.story.sentences,
      cues: cues,
      now: now,
      cheer: now.flatMap { date in finishedAt.map { date.timeIntervalSince($0) } },
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
