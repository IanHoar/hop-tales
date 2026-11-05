import Content
import DesignSystem
import QuartzCore
import SwiftUI
import World

struct PlusTaste: View {
  static let friend = Friend.cat

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.freezesMotion) private var freezesMotion
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var read = 0
  @State private var progress = 900.0
  @State private var isShown = true
  @State private var cycle = 0
  @State private var hopStart: TimeInterval?

  private let words: [String] = {
    let story = StoryLibrary.all.first { $0.id == "wool-in-the-wind" }
    return story?.sentences.first?.words.map { $0.leading + $0.text + $0.trailing }
      ?? PlusTaste.friend.examples
  }()

  var body: some View {
    GeometryReader { proxy in
      MeadowBackdrop(
        progress: progress,
        mood: Mood(sky: colorScheme == .dark ? .night : .day),
        world: Self.friend
      )
      .id(cycle)
        .frame(width: proxy.size.width * 2, height: proxy.size.height * 2)
        .scaleEffect(0.5, anchor: .topLeading)
    }
    .overlay(alignment: .top) {
      sentence.padding(.top, 10)
    }
    .overlay(alignment: .bottom) {
      friend
        .shadow(color: Paper.shadow, radius: 4, y: 3)
        .offset(y: 8)
    }
    .opacity(isShown ? 1 : 0)
    .frame(height: 170)
    .clipShape(.rect(cornerRadius: 14))
    .accessibilityHidden(true)
    .task { await loop() }
  }

  @ViewBuilder private var friend: some View {
    if freezesMotion || reduceMotion {
      IdleFriend(Self.friend, look: nil, height: 64)
    } else {
      TimelineView(.animation) { _ in
        let now = CACurrentMediaTime()
        let hop = hopStart.map { now - $0 } ?? 1
        let index = Int(min(hop, 1) * Self.fps)
        if index < 8 {
          let arc = sin(.pi * min(max((hop * Self.fps - 1) / 6, 0), 1))
          HareSprite(HareFrame(.hop, index, friend: Self.friend), height: 64)
            .offset(y: -10 * arc)
        } else {
          let breath = IdleMotion.breathing(at: now)
          HareSprite(HareFrame(.idle, IdleMotion.frame(at: now), friend: Self.friend), height: 64)
            .scaleEffect(x: breath.x, y: breath.y, anchor: .bottom)
        }
      }
      .frame(height: 64)
    }
  }

  private static let fps = 14.0

  private var sentence: some View {
    words.enumerated().reduce(Text("")) { line, item in
      let (index, word) = item
      let colour = index < read ? Paper.ink : index == read ? Paper.redInk : Paper.muted
      return line + Text(index == 0 ? word : " \(word)").foregroundStyle(colour)
    }
    .font(Typography.word(17))
    .multilineTextAlignment(.center)
    .lineLimit(2)
    .padding(.horizontal, 14)
    .padding(.vertical, 6)
    .background(Paper.paper.opacity(0.92), in: .rect(cornerRadius: 12))
    .padding(.horizontal, 12)
  }

  private func loop() async {
    guard !freezesMotion, !reduceMotion else { return }
    while !Task.isCancelled {
      for index in 1...words.count {
        try? await Task.sleep(for: .seconds(1.5))
        withAnimation(.easeOut(duration: 0.2)) { read = index }
        hopStart = CACurrentMediaTime()
        progress += Story.stepPerWord
      }
      try? await Task.sleep(for: .seconds(2.2))
      withAnimation(.easeInOut(duration: 0.4)) { isShown = false }
      try? await Task.sleep(for: .seconds(0.45))
      read = 0
      progress = 900
      cycle += 1
      try? await Task.sleep(for: .seconds(0.6))
      withAnimation(.easeInOut(duration: 0.4)) { isShown = true }
    }
  }
}
