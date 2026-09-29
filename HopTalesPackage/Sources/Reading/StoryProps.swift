import Content
import DesignSystem
import SwiftUI
import World

struct PropKey: Hashable {
  let sentence: Int
  let index: Int
}

struct PropCue: Equatable {
  var revealed: Date
  var ended: Date?
}

enum PropTiming {
  static let afterWord: TimeInterval = 0.35
  static let sentenceStart: TimeInterval = 0.9
  static let exit: TimeInterval = 0.6
  static let dash: TimeInterval = 1.1

  static func cues(
    _ cues: [PropKey: PropCue], story: Story, at position: HopTarget, now: Date
  ) -> [PropKey: PropCue] {
    var cues = cues.filter { $0.key.sentence <= position.sentence }
    let over = position.sentence >= story.sentences.count
    for key in cues.keys where key.sentence < position.sentence && cues[key]?.ended == nil {
      guard !lingers(key, in: story, at: position) else { continue }
      cues[key]?.ended = now
    }
    for (sentenceIndex, sentence) in story.sentences.enumerated().prefix(position.sentence) {
      for index in sentence.events.indices {
        let key = PropKey(sentence: sentenceIndex, index: index)
        guard cues[key] == nil, lingers(key, in: story, at: position) else { continue }
        cues[key] = PropCue(revealed: now.addingTimeInterval(afterWord))
      }
    }
    guard let sentence = story.sentences[safe: position.sentence] else { return cues }
    for (index, event) in sentence.events.enumerated() where shows(event, at: position.word) {
      let key = PropKey(sentence: position.sentence, index: index)
      guard cues[key] == nil else { continue }
      let delay = event.after == nil ? sentenceStart : afterWord
      cues[key] = PropCue(revealed: now.addingTimeInterval(delay))
    }
    return cues
  }

  static func lingers(_ key: PropKey, in story: Story, at position: HopTarget) -> Bool {
    guard position.sentence < story.sentences.count,
      let sentence = story.sentences[safe: key.sentence],
      let event = sentence.events[safe: key.index]
    else { return false }
    if event.isCompanion { return true }
    return key.sentence == position.sentence - 1 && carries(event, in: sentence)
  }

  static func carries(_ event: StoryEvent, in sentence: Sentence) -> Bool {
    event.after == sentence.words.count - 1
  }

  static func shows(_ event: StoryEvent, at word: Int) -> Bool {
    event.after.map { $0 < word } ?? true
  }
}

struct StoryPropLayer: View {
  let path: WordPath
  let sentences: [Sentence]
  let position: HopTarget
  let cameraX: CGFloat
  let cues: [PropKey: PropCue]
  let now: Date?
  let tint: Color
  let world: Friend

  private var geometry: ReadingGeometry { path.geometry }

  var body: some View {
    ZStack {
      ForEach(items, id: \.id) { item in
        PropFigure(item: item, geometry: geometry, now: now)
      }
    }
    .frame(width: geometry.size.width, height: geometry.size.height)
    .colorMultiply(tint)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private var items: [PropItem] {
    var items: [PropItem] = []
    for (sentenceIndex, sentence) in sentences.enumerated() {
      for (index, event) in sentence.events.enumerated() {
        guard let prop = StoryProp.named(event.prop) else { continue }
        let key = PropKey(sentence: sentenceIndex, index: index)
        let cue: PropCue?
        if now == nil {
          guard stillShows(event, sentence: sentenceIndex) else { continue }
          cue = nil
        } else {
          guard let found = cues[key] else { continue }
          let exit = event.isCompanion ? PropTiming.dash : PropTiming.exit
          if let ended = found.ended, let now, now.timeIntervalSince(ended) > exit { continue }
          cue = found
        }
        for copy in 0..<max(1, event.count) {
          items.append(
            PropItem(
              id: "\(sentenceIndex)-\(index)-\(copy)",
              name: event.prop,
              prop: prop,
              height: prop.height(in: world),
              copy: copy,
              copies: max(1, event.count),
              seed: sentenceIndex * 7 + index * 3 + copy,
              anchor: anchor(sentence: sentenceIndex, event: event),
              baseline: baseline(for: event, height: prop.height(in: world)),
              cue: cue,
              companion: event.isCompanion,
              thought: event.isThought
            )
          )
        }
      }
    }
    return items
  }

  static let companionLead: CGFloat = 70
  static let companionDrop: CGFloat = 28
  static let thoughtLead: CGFloat = 46
  static let thoughtLift: CGFloat = 12
  static let carriedLead: CGFloat = 84

  private func stillShows(_ event: StoryEvent, sentence: Int) -> Bool {
    guard sentence < position.sentence else {
      return sentence == position.sentence && PropTiming.shows(event, at: position.word)
    }
    guard position.sentence < sentences.count else { return false }
    return event.isCompanion
      || sentence == position.sentence - 1 && PropTiming.carries(event, in: sentences[sentence])
  }

  private func anchor(sentence: Int, event: StoryEvent) -> CGFloat {
    if event.isCompanion { return path.hareX + geometry.path(Self.companionLead) }
    if event.isThought { return path.hareX + geometry.path(Self.thoughtLead) }
    if sentence < position.sentence, PropTiming.carries(event, in: sentences[sentence]) {
      return path.hareX + geometry.path(Self.carriedLead)
    }
    let words = sentences[sentence].words.count
    let word = min((event.after ?? -1) + 1, words - 1)
    guard let stop = path.stop(at: HopTarget(sentence: sentence, word: word)) else {
      return geometry.size.width * 0.7
    }
    let gap = Self.propGap * CGFloat(neighbours(of: event, in: sentence))
    return stop.centre + geometry.path(48 + gap) - cameraX
  }

  static let propGap: CGFloat = 64

  private func neighbours(of event: StoryEvent, in sentence: Int) -> Int {
    let events = sentences[sentence].events
    guard let index = events.firstIndex(of: event) else { return 0 }
    return events.prefix(index).filter {
      $0.after == event.after && $0.resolvedPlace == event.resolvedPlace
        && !$0.isCompanion && !$0.isThought
    }.count
  }

  private func baseline(for event: StoryEvent, height: Double) -> CGFloat {
    if event.isCompanion { return path.hareFeetY + geometry.path(Self.companionDrop) }
    if event.isThought {
      return path.hareFeetY - path.hareHeight(hopping: false) - geometry.path(Self.thoughtLift)
    }
    return switch event.resolvedPlace {
    case .ground: path.signFeetY
    case .near: path.wordY + path.wordHeight / 2 + geometry.path(10 + height)
    case .sky: path.signFeetY - geometry.path(300)
    }
  }
}

struct PropItem {
  let id: String
  let name: String
  let prop: StoryProp
  let height: Double
  let copy: Int
  let copies: Int
  let seed: Int
  let anchor: CGFloat
  let baseline: CGFloat
  let cue: PropCue?
  var companion = false
  var thought = false
}

struct PropFigure: View {
  let item: PropItem
  let geometry: ReadingGeometry
  let now: Date?

  var body: some View {
    if item.thought { thinking } else { figure }
  }

  private var thinking: some View {
    let pose = PropPose.thinking(time: elapsed, exit: exit, unit: geometry.path(1))
    let size = ThoughtBubble.size(in: geometry)
    return ThoughtBubble(art: art(frame: 1), geometry: geometry)
      .scaleEffect(pose.scale, anchor: .bottomLeading)
      .opacity(pose.opacity)
      .position(x: item.anchor + size.width / 2, y: item.baseline - size.height / 2 + pose.dy)
  }

  @ViewBuilder
  private var figure: some View {
    let height = geometry.path(item.height)
    let spread = CGFloat(item.copy) - CGFloat(item.copies - 1) / 2
    let pose = PropPose.at(
      item: item,
      elapsed: elapsed,
      exit: exit,
      width: geometry.size.width,
      unit: geometry.path(1)
    )
    Sticker(art(frame: pose.frame), height: height)
      .scaleEffect(x: pose.flip ? -1 : 1, y: 1)
      .scaleEffect(pose.scale, anchor: .bottom)
      .rotationEffect(.degrees(pose.rotation), anchor: pose.pivotsAtBase ? .bottom : .center)
      .opacity(pose.opacity)
      .position(
        x: item.anchor + pose.dx + spread * height * 1.3,
        y: item.baseline - height / 2 + pose.dy
      )
  }

  private var elapsed: TimeInterval? {
    guard let now, let cue = item.cue else { return nil }
    return now.timeIntervalSince(cue.revealed) - Double(item.copy) * 0.25
  }

  private var exit: Double {
    guard let now, let ended = item.cue?.ended else { return 0 }
    let duration = item.companion ? PropTiming.dash : PropTiming.exit
    return min(1, max(0, now.timeIntervalSince(ended) / duration))
  }

  private func art(frame: Int) -> String {
    item.prop.motion.frames == 2 ? "cast-\(item.name)-\(frame)" : "cast-\(item.name)"
  }
}

struct TVStoryProps: View {
  let story: Story
  let position: HopTarget
  let geometry: ReadingGeometry
  let world: Friend
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var cues: [PropKey: PropCue] = [:]

  var body: some View {
    Group {
      if reduceMotion {
        layer(now: nil)
          .id(position)
          .transition(.opacity)
      } else {
        TimelineView(.animation) { context in layer(now: context.date) }
      }
    }
    .animation(.easeInOut(duration: 0.6), value: position)
    .onChange(of: position) { old, new in
      let backward = (new.sentence, new.word) < (old.sentence, old.word)
      cues = PropTiming.cues(backward ? [:] : cues, story: story, at: new, now: .now)
    }
    .onAppear { cues = PropTiming.cues([:], story: story, at: position, now: .now) }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private func layer(now: Date?) -> some View {
    ZStack {
      ForEach(items(now: now), id: \.id) { item in
        PropFigure(item: item, geometry: geometry, now: now)
      }
    }
    .frame(width: geometry.size.width, height: geometry.size.height)
  }

  private func items(now: Date?) -> [PropItem] {
    guard let sentence = story.sentences[safe: position.sentence] else { return [] }
    let ground = geometry.y(geometry.metrics.card.origin.y) - geometry.scaled(24)
    return sentence.events.enumerated().flatMap { index, event -> [PropItem] in
      guard let prop = StoryProp.named(event.prop) else { return [] }
      let key = PropKey(sentence: position.sentence, index: index)
      if now == nil, !PropTiming.shows(event, at: position.word) { return [] }
      if now != nil, cues[key] == nil { return [] }
      let place = event.resolvedPlace
      let baseline = place == .sky ? geometry.size.height * 0.32 : ground
      let anchor = geometry.size.width * (0.58 + 0.14 * CGFloat(index % 3))
      return (0..<max(1, event.count)).map { copy in
        PropItem(
          id: "\(position.sentence)-\(index)-\(copy)", name: event.prop, prop: prop,
          height: prop.height(in: world), copy: copy,
          copies: max(1, event.count), seed: position.sentence * 7 + index * 3 + copy,
          anchor: anchor, baseline: baseline, cue: now == nil ? nil : cues[key]
        )
      }
    }
  }
}
