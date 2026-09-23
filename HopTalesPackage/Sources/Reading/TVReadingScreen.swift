import ComposableArchitecture2
import DesignSystem
import SwiftUI
import World

public struct TVReadingScreen: View {
  let store: StoreOf<Reading>

  public init(store: StoreOf<Reading>) {
    self.store = store
  }

  public var body: some View {
    GeometryReader { proxy in
      let geometry = ReadingGeometry(metrics: .tv, size: proxy.size)
      ZStack(alignment: .topLeading) {
        TVWorld(progress: store.worldProgress)
        topBar(geometry)
          .padding(.horizontal, geometry.scaled(geometry.metrics.sidePadding))
          .offset(y: geometry.y(geometry.metrics.topBarY))
        SentenceStrip(
          sentences: store.story.sentences.map(\.words),
          position: BallTarget(sentence: store.sentenceIndex, word: store.wordIndex),
          isSpeaking: store.isSpeaking,
          geometry: geometry
        )
        .position(geometry.cardCenter)
        ProgressRail(story: store.story, sentenceIndex: store.sentenceIndex, geometry: geometry)
          .frame(width: geometry.progressWidth)
          .position(x: proxy.size.width / 2, y: geometry.progressY)
      }
    }
    .background(Palette.duskRoot)
    .accessibilityHidden(true)
  }

  private func topBar(_ geometry: ReadingGeometry) -> some View {
    HStack {
      Text(store.story.title.uppercased())
        .font(Typography.caps(geometry.scaled(18)))
        .tracking(geometry.scaled(3))
        .foregroundStyle(Palette.chipText)
        .padding(.horizontal, geometry.scaled(22))
        .padding(.vertical, geometry.scaled(12))
        .background(Palette.cream.opacity(0.9), in: .capsule)
      Spacer()
      HStack(spacing: geometry.scaled(10)) {
        Star()
          .fill(Palette.amber)
          .frame(width: geometry.scaled(26), height: geometry.scaled(26))
        Text("\(store.stars)")
          .font(Typography.ui(geometry.scaled(26)))
          .foregroundStyle(Palette.ink)
      }
      .padding(.horizontal, geometry.scaled(24))
      .frame(height: geometry.scaled(64))
      .background(Palette.cream, in: .capsule)
    }
  }
}
