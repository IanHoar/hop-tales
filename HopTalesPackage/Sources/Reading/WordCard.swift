import Content
import DesignSystem
import SwiftUI

struct WordCard: View {
  let words: [Word]
  let currentIndex: Int
  var recognisedIndex: Int?
  let geometry: ReadingGeometry
  var sceneShadow: Color = Palette.SceneShadow.meadow

  var body: some View {
    ZStack(alignment: .top) {
      Ball(wordIndex: currentIndex, geometry: geometry)
        .padding(.top, geometry.scaled(14))

      WordRow(
        words: words,
        currentIndex: currentIndex,
        recognisedIndex: recognisedIndex,
        geometry: geometry
      )
        .frame(height: geometry.scaled(84))
        .padding(.top, geometry.scaled(96))
    }
    .frame(width: geometry.cardSize.width, height: geometry.cardSize.height, alignment: .top)
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
