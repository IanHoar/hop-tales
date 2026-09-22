import Content
import DesignSystem
import SwiftUI

/// The reading surface: the ball lane on top, the word row under it, on a cream card.
///
/// The card never moves between stages — only the world behind it changes.
struct WordCard: View {
  let words: [Word]
  let currentIndex: Int
  let geometry: ReadingGeometry
  var sceneShadow: Color = Palette.SceneShadow.meadow

  var body: some View {
    ZStack(alignment: .top) {
      Ball(wordIndex: currentIndex, geometry: geometry)
        .padding(.top, geometry.scaled(14))

      WordRow(words: words, currentIndex: currentIndex, geometry: geometry)
        .frame(height: geometry.scaled(84))
        .padding(.top, geometry.scaled(96))
    }
    .frame(width: geometry.cardSize.width, height: geometry.cardSize.height, alignment: .top)
    .background(Palette.cream, in: shape)
    .clipShape(shape)
    .shadow(color: Palette.ink.opacity(0.10), radius: 0, x: 0, y: geometry.scaled(12))
    .shadow(color: sceneShadow.opacity(0.18), radius: geometry.scaled(20), x: 0, y: geometry.scaled(24))
  }

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: geometry.cardCornerRadius, style: .continuous)
  }
}

#Preview("Word card") {
  let story = StoryLibrary.all[0]
  return GeometryReader { proxy in
    let geometry = ReadingGeometry(size: proxy.size)
    ZStack {
      Color(hex: 0x8FCB6B).ignoresSafeArea()
      VStack(spacing: geometry.scaled(24)) {
        ForEach([0, 2, 5], id: \.self) { index in
          WordCard(words: story.sentences[0].words, currentIndex: index, geometry: geometry)
        }
      }
      .frame(maxHeight: .infinity)
    }
  }
}
