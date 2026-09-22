import Content
import DesignSystem
import SwiftUI

struct SentenceStrip: View {
  let sentences: [[Word]]
  let position: BallTarget
  var flash: BallTarget?
  var isSpeaking = false
  let geometry: ReadingGeometry
  @State private var settled: BallTarget?

  private var shown: BallTarget { settled ?? position }
  private var gap: CGFloat { geometry.scaled(24) }
  private var pitch: CGFloat { geometry.cardSize.width + gap }

  var body: some View {
    HStack(spacing: gap) {
      ForEach(sentences.indices, id: \.self) { index in
        WordCard(
          words: sentences[index],
          currentIndex: currentIndex(of: index),
          recognisedIndex: flash?.sentence == index ? flash?.word : nil,
          isSpeaking: isSpeaking && index == shown.sentence,
          geometry: geometry,
          showsBall: false
        )
      }
    }
    .fixedSize()
    .offset(x: (CGFloat(sentences.count - 1) / 2 - CGFloat(shown.sentence)) * pitch)
    .frame(width: geometry.cardSize.width, height: geometry.cardSize.height)
    .overlay(alignment: .top) {
      Ball(target: position, geometry: geometry, hop: hop(to:), onSettle: settle)
        .padding(.top, geometry.scaled(14))
    }
    .onAppear {
      if settled == nil { settled = position }
    }
  }

  private func currentIndex(of sentence: Int) -> Int {
    if sentence < shown.sentence { return sentences[sentence].count }
    if sentence == shown.sentence { return shown.word }
    return 0
  }

  private func hop(to target: BallTarget) -> BallHop {
    let from = shown
    if target.sentence == from.sentence {
      return BallHop(
        distance: WordRow.hopDistance(
          words: sentences[safe: from.sentence] ?? [],
          from: from.word,
          to: target.word,
          geometry: geometry
        )
      )
    }
    guard target.sentence > from.sentence, sentences.indices.contains(target.sentence) else {
      return BallHop()
    }
    return BallHop(distance: pitch * CGFloat(target.sentence - from.sentence), carried: true)
  }

  private func settle(_ target: BallTarget, _ animation: Animation?) {
    guard let animation else {
      settled = target
      return
    }
    withAnimation(animation) { settled = target }
  }
}
