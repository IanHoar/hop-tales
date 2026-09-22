import Content
import DesignSystem
import SwiftUI

#if DEBUG
struct ProgressRailPreview: View {
  enum Variant {
    case firstSentence
    case midStory
    case sentenceWithANewWord
    case lastSentence
  }

  let variant: Variant

  init(_ variant: Variant) {
    self.variant = variant
  }

  var body: some View {
    let geometry = ReadingGeometry(size: Metrics.phone.reference)
    ZStack {
      Color(hex: 0x8FCB6B)
      ProgressRail(story: story, sentenceIndex: sentenceIndex, geometry: geometry)
    }
    .frame(width: Metrics.phone.reference.width, height: 120)
  }

  private var story: Story {
    variant == .sentenceWithANewWord ? StoryLibrary.all[1] : StoryLibrary.all[0]
  }

  private var sentenceIndex: Int {
    switch variant {
    case .firstSentence: 0
    case .midStory: 2
    case .sentenceWithANewWord: 2
    case .lastSentence: story.sentences.count - 1
    }
  }
}

#Preview("First sentence") { ProgressRailPreview(.firstSentence) }
#Preview("Mid story") { ProgressRailPreview(.midStory) }
#Preview("New word") { ProgressRailPreview(.sentenceWithANewWord) }
#Preview("Last sentence") { ProgressRailPreview(.lastSentence) }
#endif
