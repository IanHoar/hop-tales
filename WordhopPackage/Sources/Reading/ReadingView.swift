import ComposableArchitecture2
import Content
import DesignSystem
import SwiftUI
import World

/// Milestone 1 chrome: the word card, ball and mic pill on a flat background.
///
/// The reading surface never moves — the card, ball, mic pill and progress rail sit in the same
/// place on every stage; only the world behind them changes. Text stays in SwiftUI (SpriteKit text
/// rendering is not good enough for the reading surface).
///
/// TODO(#2, #3): the ball, and the word-to-pill morph on a recognised word.
/// TODO(#4, #5): the progress rail and the real mic pill.
/// TODO(#14): `SpriteView(scene:options: [.allowsTransparency])` behind this chrome.
/// TODO(#22): a `horizontalSizeClass == .regular` branch matching the iPad artboard.
public struct ReadingView: View {
  let store: StoreOf<Reading>

  public init(store: StoreOf<Reading>) {
    self.store = store
  }

  public var body: some View {
    GeometryReader { proxy in
      let geometry = ReadingGeometry(size: proxy.size)

      ZStack {
        Color(hex: 0x8FCB6B)  // flat meadow green until the world lands
          .ignoresSafeArea()

        WordCard(
          words: store.sentence?.words ?? [],
          currentIndex: store.wordIndex,
          geometry: geometry
        )
        .position(geometry.cardCenter)
        .onTapGesture { store.send(.currentWordTapped) }

        micPill(geometry)
          .position(x: proxy.size.width / 2, y: geometry.y(762))
      }
    }
    .navigationTitle(store.story.title)
    .navigationBarTitleDisplayMode(.inline)
  }

  private func micPill(_ geometry: ReadingGeometry) -> some View {
    Label(
      store.heardToken.map { "Heard it — “\($0)”" } ?? "Say the word",
      systemImage: store.heardToken == nil ? "mic.fill" : "checkmark"
    )
    .font(Typography.ui(geometry.scaled(15)))
    .foregroundStyle(store.heardToken == nil ? Palette.chipText : Palette.heardText)
    .padding(.horizontal, geometry.scaled(18))
    .padding(.vertical, geometry.scaled(12))
    .background(store.heardToken == nil ? Palette.cream : Palette.heardBg, in: .capsule)
    .shadow(color: Palette.ink.opacity(0.12), radius: 0, x: 0, y: geometry.scaled(4))
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
