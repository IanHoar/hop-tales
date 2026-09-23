import ComposableArchitecture2
import DesignSystem
import SwiftUI
import World

public struct TVReadingScreen: View {
  let store: StoreOf<Reading>

  public init(store: StoreOf<Reading>) {
    self.store = store
  }

  static func chrome(_ factor: CGFloat) -> ReadingGeometry {
    let reference = Metrics.phone.reference
    return ReadingGeometry(
      metrics: .phone,
      size: CGSize(width: reference.width * factor, height: reference.height * factor)
    )
  }

  public var body: some View {
    GeometryReader { proxy in
      let geometry = ReadingGeometry(metrics: .tv, size: proxy.size)
      let tvScale = proxy.size.width / Metrics.tv.reference.width
      let ribbon = Self.chrome(1.7 * tvScale)
      let chips = Self.chrome(1.5 * tvScale)
      let trail = Self.chrome(2.5 * tvScale)
      ZStack(alignment: .topLeading) {
        TVWorld(progress: store.worldProgress)
        HStack(alignment: .center) {
          StoryRibbon(title: store.story.title, geometry: ribbon)
          Spacer()
          HStack(spacing: chips.scaled(12)) {
            MicPill(heardToken: nil, geometry: chips, animatesBars: false)
            StarTotal(stars: store.stars, geometry: chips)
          }
        }
        .padding(.horizontal, geometry.scaled(geometry.metrics.sidePadding))
        .offset(y: geometry.y(geometry.metrics.topBarY))
        SentenceStrip(
          sentences: store.story.sentences.map(\.words),
          position: BallTarget(sentence: store.sentenceIndex, word: store.wordIndex),
          isSpeaking: store.isSpeaking,
          geometry: geometry
        )
        .position(geometry.cardCenter)
        ProgressRail(story: store.story, sentenceIndex: store.sentenceIndex, geometry: trail)
          .position(x: proxy.size.width / 2, y: geometry.progressY)
      }
    }
    .background(Palette.duskRoot)
    .accessibilityHidden(true)
  }
}
