import ComposableArchitecture2
import Content
import DesignSystem
import SwiftUI
import World

/// Milestone 1 chrome: the word card, ball and mic pill on a flat background.
///
/// The reading surface never moves — the card, ball, mic pill and progress rail sit in the same
/// place on every stage; only the world behind them changes. Text stays in SwiftUI (SpriteKit
/// text rendering is not good enough for the reading surface).
///
/// TODO(milestone-1): ball hop, recognised morph to pill, sparkles, mic bars, progress rail.
/// TODO(milestone-2): `SpriteView(scene:options: [.allowsTransparency])` behind this chrome.
/// TODO(milestone-4): `horizontalSizeClass == .regular` branch matching the iPad artboard.
public struct ReadingView: View {
  let store: StoreOf<Reading>
  private let metrics = Metrics.phone

  public init(store: StoreOf<Reading>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      Color(hex: 0x8FCB6B)  // flat meadow green until the world lands
        .ignoresSafeArea()

      VStack(spacing: 0) {
        Spacer()
        wordCard
        Spacer()
        micPill
          .padding(.bottom, 40)
      }
      .padding(.horizontal, metrics.card.origin.x)
    }
    .navigationTitle(store.story.title)
    .navigationBarTitleDisplayMode(.inline)
  }

  private var wordCard: some View {
    ZStack(alignment: .bottom) {
      RoundedRectangle(cornerRadius: metrics.card.cornerRadius, style: .continuous)
        .fill(Palette.cream)
        .shadow(color: Palette.ink.opacity(0.10), radius: 0, x: 0, y: 12)
        .shadow(color: Palette.ink.opacity(0.18), radius: 40, x: 0, y: 24)

      wordRow
        .padding(.bottom, 28)
    }
    .frame(height: metrics.card.size.height)
  }

  private var wordRow: some View {
    HStack(spacing: metrics.words.gap) {
      ForEach(Array((store.sentence?.words ?? []).enumerated()), id: \.offset) { index, word in
        let position = index - store.wordIndex
        Text(word.text)
          .font(Typography.word(position == 0 ? metrics.words.current : metrics.words.side))
          .foregroundStyle(colour(for: position))
          .padding(.horizontal, position < 0 ? 9 : 0)
          .padding(.vertical, position < 0 ? 3 : 0)
          .background(position < 0 ? Palette.pillBg : .clear, in: .rect(cornerRadius: 10))
      }
    }
    .frame(maxWidth: .infinity)
    .clipped()
    .onTapGesture { store.send(.currentWordTapped) }
  }

  private func colour(for position: Int) -> Color {
    switch position {
    case ..<0: Palette.pillText
    case 0: Palette.ink
    case 1: Palette.muted
    default: Palette.faint
    }
  }

  private var micPill: some View {
    Label(
      store.heardToken.map { "Heard it — “\($0)”" } ?? "Say the word",
      systemImage: store.heardToken == nil ? "mic.fill" : "checkmark"
    )
    .font(Typography.ui(15))
    .foregroundStyle(store.heardToken == nil ? Palette.chipText : Palette.heardText)
    .padding(.horizontal, 18)
    .padding(.vertical, 12)
    .background(store.heardToken == nil ? Palette.cream : Palette.heardBg, in: .capsule)
    .shadow(color: Palette.ink.opacity(0.12), radius: 0, x: 0, y: 4)
  }
}

#Preview {
  NavigationStack {
    ReadingView(
      store: Store(initialState: Reading.State(story: StoryLibrary.all[0])) {
        Reading()
      }
    )
  }
}
