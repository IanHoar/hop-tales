import Content
import DesignSystem
import SwiftUI

struct WordCard: View {
  let words: [Word]
  let currentIndex: Int
  var recognisedIndex: Int?
  var isSpeaking = false
  let geometry: ReadingGeometry
  var sceneShadow: Color = Palette.SceneShadow.meadow
  var showsBall = true

  var body: some View {
    ZStack(alignment: .top) {
      if showsBall {
        Ball(target: BallTarget(sentence: 0, word: currentIndex), geometry: geometry)
          .padding(.top, geometry.scaled(14))
      }

      WordRow(
        words: words,
        currentIndex: currentIndex,
        recognisedIndex: recognisedIndex,
        isSpeaking: isSpeaking,
        geometry: geometry
      )
        .frame(height: geometry.scaled(84))
        .padding(.top, geometry.scaled(96))
    }
    .frame(width: geometry.cardSize.width, height: geometry.cardSize.height, alignment: .top)
    .clipShape(shape)
    .bevel(
      Palette.parchment,
      lip: Palette.parchmentLip,
      shape: shape,
      border: geometry.scaled(4),
      drop: geometry.scaled(6),
      lipHeight: geometry.scaled(9)
    )
    .background {
      shape
        .fill(Palette.outline)
        .shadow(
          color: Color(hex: 0x0C0A1E, opacity: 0.32),
          radius: geometry.scaled(17),
          x: 0,
          y: geometry.scaled(16)
        )
        .offset(y: geometry.scaled(6))
    }
  }

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: geometry.cardCornerRadius, style: .continuous)
  }
}
