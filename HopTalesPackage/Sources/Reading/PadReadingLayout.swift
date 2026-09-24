import ComposableArchitecture2
import DesignSystem
import SwiftUI

struct PadReadingLayout<World: View, Card: View>: View {
  static var chromeFactor: CGFloat { 1.08 }

  let store: StoreOf<Reading>
  let size: CGSize
  let heldToken: String?
  let hearing: String?
  let chip: Reading.State.Recognised?
  @ViewBuilder let world: () -> World
  @ViewBuilder let card: (ReadingGeometry) -> Card

  var body: some View {
    let geometry = ReadingGeometry(metrics: .pad, size: size)
    let chrome = TVReadingScreen.chrome(Self.chromeFactor * geometry.scale)
    ZStack(alignment: .topLeading) {
      world()
        .ignoresSafeArea()
      HStack(spacing: chrome.scaled(14)) {
        BackButton(geometry: chrome) { store.send(.backTapped) }
        StoryRibbon(title: store.story.title, geometry: chrome)
        Spacer(minLength: chrome.scaled(16))
        MicPill(heardToken: heldToken, hearing: hearing, geometry: chrome)
        StarTotal(stars: store.stars, geometry: chrome)
      }
      .padding(.horizontal, geometry.scaled(geometry.metrics.sidePadding))
      .padding(.top, geometry.scaled(12))
      card(geometry)
        .frame(width: size.width)
        .offset(y: geometry.y(geometry.metrics.card.origin.y))
      if let chip {
        StarChip(stars: chip.stars, geometry: chrome)
          .id(chip.count)
          .position(
            x: size.width - geometry.scaled(geometry.metrics.sidePadding) - chrome.scaled(50),
            y: geometry.scaled(12) + chrome.scaled(96)
          )
      }
      #if DEBUG
        DebugControls(store: store)
          .position(x: size.width / 2, y: geometry.y(260))
      #endif
    }
    .frame(width: size.width, height: size.height)
  }
}
