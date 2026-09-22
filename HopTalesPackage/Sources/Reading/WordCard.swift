import Content
import DesignSystem
import SwiftUI

struct WordCard: View {
  let words: [Word]
  let currentIndex: Int
  var recognisedIndex: Int?
  var completionCount = 0
  var isSpeaking = false
  let geometry: ReadingGeometry
  var sceneShadow: Color = Palette.SceneShadow.meadow
  @State private var settledIndex: Int?
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.freezesMotion) private var freezesMotion

  private var displayedIndex: Int {
    min(settledIndex ?? currentIndex, currentIndex)
  }

  var body: some View {
    ZStack(alignment: .top) {
      Ball(
        wordIndex: currentIndex,
        settledIndex: displayedIndex,
        words: words,
        completionCount: completionCount,
        geometry: geometry
      ) { index in
        withAnimation(Motion.slide) { settledIndex = index }
      }
      .padding(.top, geometry.scaled(14))

      WordRow(
        words: words,
        currentIndex: displayedIndex,
        recognisedIndex: recognisedIndex,
        isSpeaking: isSpeaking,
        geometry: geometry
      )
        .frame(height: geometry.scaled(84))
        .padding(.top, geometry.scaled(96))
    }
    .frame(width: geometry.cardSize.width, height: geometry.cardSize.height, alignment: .top)
    .onChange(of: currentIndex, initial: true) { old, new in
      if settledIndex == nil { settledIndex = old }
      if reduceMotion || freezesMotion { settledIndex = new }
    }
    .background(Palette.cream, in: shape)
    .clipShape(shape)
    .shadow(color: Palette.ink.opacity(0.10), radius: 0, x: 0, y: geometry.scaled(12))
    .shadow(
      color: sceneShadow.opacity(0.18),
      radius: geometry.scaled(20),
      x: 0,
      y: geometry.scaled(24)
    )
  }

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: geometry.cardCornerRadius, style: .continuous)
  }
}
