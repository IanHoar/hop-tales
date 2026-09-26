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

  static func cues(
    _ cues: [PropKey: PropCue], story: Story, at position: HopTarget, now: Date
  ) -> [PropKey: PropCue] {
    var cues = cues.filter { $0.key.sentence <= position.sentence }
    for key in cues.keys where key.sentence < position.sentence && cues[key]?.ended == nil {
      cues[key]?.ended = now
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
          let showing = PropTiming.shows(event, at: position.word)
          guard sentenceIndex == position.sentence, showing else { continue }
          cue = nil
        } else {
          guard let found = cues[key] else { continue }
          if let ended = found.ended, let now, now.timeIntervalSince(ended) > PropTiming.exit {
            continue
          }
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
              baseline: baseline(for: event.resolvedPlace, height: prop.height(in: world)),
              cue: cue
            )
          )
        }
      }
    }
    return items
  }

  private func anchor(sentence: Int, event: StoryEvent) -> CGFloat {
    let words = sentences[sentence].words.count
    let word = min((event.after ?? -1) + 1, words - 1)
    guard let stop = path.stop(at: HopTarget(sentence: sentence, word: word)) else {
      return geometry.size.width * 0.7
    }
    return stop.centre + geometry.path(48) - cameraX
  }

  private func baseline(for place: StoryEvent.Place, height: Double) -> CGFloat {
    switch place {
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
}

struct PropFigure: View {
  let item: PropItem
  let geometry: ReadingGeometry
  let now: Date?

  var body: some View {
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
    return min(1, max(0, now.timeIntervalSince(ended) / PropTiming.exit))
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
