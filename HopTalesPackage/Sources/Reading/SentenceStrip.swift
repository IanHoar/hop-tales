import Content
import DesignSystem
import SwiftUI

struct SentenceStrip: View {
  let sentences: [[Word]]
  let position: HopTarget
  var flash: HopTarget?
  var isSpeaking = false
  let geometry: ReadingGeometry
  var screenWidth: CGFloat?
  @State private var settled: HopTarget?

  private var shown: HopTarget { settled ?? position }
  private var gap: CGFloat {
    let margin = screenWidth.map { max(($0 - geometry.cardSize.width) / 2, 0) } ?? 0
    return margin + geometry.scaled(24)
  }
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
          showsHare: false
        )
      }
    }
    .fixedSize()
    .offset(x: (CGFloat(sentences.count - 1) / 2 - CGFloat(shown.sentence)) * pitch)
    .frame(width: geometry.cardSize.width, height: geometry.cardSize.height)
    .overlay(alignment: .top) {
      Hare(target: position, geometry: geometry, hop: hop(to:), onSettle: settle)
        .offset(y: geometry.scaled(Hare.feetBelowCardTop))
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

  private func hop(to target: HopTarget) -> HopPlan {
    let from = shown
    if target.sentence == from.sentence {
      return HopPlan(
        distance: WordRow.hopDistance(
          words: sentences[safe: from.sentence] ?? [],
          from: from.word,
          to: target.word,
          geometry: geometry
        )
      )
    }
    guard target.sentence > from.sentence, sentences.indices.contains(target.sentence) else {
      return HopPlan()
    }
    return HopPlan(distance: pitch * CGFloat(target.sentence - from.sentence), carried: true)
  }

  private func settle(_ target: HopTarget, _ animation: Animation?) {
    guard let animation else {
      settled = target
      return
    }
    withAnimation(animation) { settled = target }
  }
}
