import Content
import DesignSystem
import SwiftUI

struct WordCard: View {
  let words: [Word]
  let currentIndex: Int
  var recognisedIndex: Int?
  var isSpeaking = false
  let geometry: ReadingGeometry
  var showsHare = true

  static let rowTop: CGFloat = 26 / 168
  static let rowHeight: CGFloat = 90 / 168
  static let dotsTop: CGFloat = 128 / 168

  var body: some View {
    let height = geometry.cardSize.height
    ZStack(alignment: .top) {
      WordRow(
        words: words,
        currentIndex: currentIndex,
        recognisedIndex: recognisedIndex,
        isSpeaking: isSpeaking,
        geometry: geometry
      )
      .frame(width: geometry.cardSize.width, height: height * Self.rowHeight)
      .mask { edgeFade.padding(.vertical, -height) }
      .padding(.top, height * Self.rowTop)
      WordDots(count: words.count, current: currentIndex, geometry: geometry)
        .padding(.top, height * Self.dotsTop)
    }
    .frame(width: geometry.cardSize.width, height: height, alignment: .top)
    .background {
      Deckle(seed: 40, jitter: geometry.scaled(2.6), step: geometry.scaled(9))
        .fill(Paper.paper)
        .shadow(
          color: Paper.shadow.opacity(1.15), radius: geometry.scaled(7), y: geometry.scaled(5)
        )
    }
    .overlay(alignment: .top) {
      if showsHare {
        Hare(target: HopTarget(sentence: 0, word: currentIndex), geometry: geometry)
          .offset(y: geometry.scaled(Hare.feetBelowCardTop))
      }
    }
  }

  private var edgeFade: some View {
    let width = geometry.cardSize.width
    let clear = min(geometry.scaled(8) / width, 0.5)
    let solid = min(geometry.scaled(36) / width, 0.5)
    return LinearGradient(
      stops: [
        .init(color: .clear, location: clear),
        .init(color: .black, location: solid),
        .init(color: .black, location: 1 - solid),
        .init(color: .clear, location: 1 - clear)
      ],
      startPoint: .leading,
      endPoint: .trailing
    )
  }
}

struct WordDots: View {
  let count: Int
  let current: Int
  let geometry: ReadingGeometry

  var body: some View {
    HStack(spacing: geometry.scaled(9)) {
      ForEach(0..<count, id: \.self) { index in
        Circle()
          .fill(fill(index))
          .overlay(Circle().strokeBorder(ring(index), lineWidth: geometry.scaled(2)))
          .frame(width: geometry.scaled(12), height: geometry.scaled(12))
      }
    }
    .animation(.easeInOut(duration: 0.25), value: current)
    .accessibilityHidden(true)
  }

  private func fill(_ index: Int) -> Color {
    if index < current { return Paper.wash }
    if index == current { return Paper.rim }
    return Paper.muted.opacity(0.25)
  }

  private func ring(_ index: Int) -> Color {
    index <= current ? Paper.washRing : Paper.muted.opacity(0.45)
  }
}
