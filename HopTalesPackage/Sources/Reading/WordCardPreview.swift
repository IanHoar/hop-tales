import Content
import DesignSystem
import SwiftUI

#if DEBUG
struct WordCardPreview: View {
  enum Variant {
    case firstWord
    case midSentence
    case lastWord
    case longWord
    case wordJustRecognised
  }

  let variant: Variant

  init(_ variant: Variant) {
    self.variant = variant
  }

  var body: some View {
    let geometry = ReadingGeometry(size: Metrics.phone.reference)
    ZStack {
      Color(hex: 0x8FCB6B)
      WordCard(
        words: sentence.words,
        currentIndex: currentIndex,
        recognisedIndex: variant == .wordJustRecognised ? currentIndex - 1 : nil,
        geometry: geometry
      )
    }
    .frame(width: Metrics.phone.reference.width, height: geometry.cardSize.height + 64)
  }

  private var sentence: Sentence {
    switch variant {
    case .firstWord, .midSentence, .lastWord, .wordJustRecognised: StoryLibrary.all[0].sentences[0]
    case .longWord: StoryLibrary.all[1].sentences[2]
    }
  }

  private var currentIndex: Int {
    switch variant {
    case .firstWord: 0
    case .midSentence, .longWord, .wordJustRecognised: 2
    case .lastWord: 5
    }
  }
}

#Preview("First word") { WordCardPreview(.firstWord) }
#Preview("Mid sentence") { WordCardPreview(.midSentence) }
#Preview("Last word") { WordCardPreview(.lastWord) }
#Preview("Long word") { WordCardPreview(.longWord) }
#Preview("Just recognised") { WordCardPreview(.wordJustRecognised) }
#endif
