import Content
import DesignSystem
import SwiftUI

#if DEBUG
struct WordCardPreview: View {
  enum Variant: String, CaseIterable {
    case firstWord
    case midSentence
    case lastWord
    case longWord
  }

  let variant: Variant

  init(_ variant: Variant) {
    self.variant = variant
  }

  var body: some View {
    let geometry = ReadingGeometry(size: Metrics.phone.reference)
    ZStack {
      Color(hex: 0x8FCB6B)
      WordCard(words: sentence.words, currentIndex: currentIndex, geometry: geometry)
    }
    .frame(width: Metrics.phone.reference.width, height: geometry.cardSize.height + 64)
  }

  private var sentence: Sentence {
    switch variant {
    case .firstWord, .midSentence, .lastWord: StoryLibrary.all[0].sentences[0]
    case .longWord: StoryLibrary.all[1].sentences[2]
    }
  }

  private var currentIndex: Int {
    switch variant {
    case .firstWord: 0
    case .midSentence, .longWord: 2
    case .lastWord: 5
    }
  }
}

struct WordCardPreviews: PreviewProvider {
  static var previews: some View {
    ForEach(WordCardPreview.Variant.allCases, id: \.self) { variant in
      WordCardPreview(variant)
        .previewDisplayName(variant.rawValue)
    }
  }
}
#endif
