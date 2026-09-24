import SwiftUI

public struct Signpost<Label: View>: View {
  static var referenceHeight: CGFloat { 172 }

  let height: CGFloat
  let label: Label

  public init(height: CGFloat, @ViewBuilder label: () -> Label) {
    self.height = height
    self.label = label()
  }

  public var body: some View {
    let image = MeadowArt.image("prop-signpost")
    let aspect = image.map { $0.size.width / max($0.size.height, 1) } ?? 0.8
    let width = height * aspect
    let unit = height / Self.referenceHeight
    ZStack(alignment: .topLeading) {
      if let image {
        Image(uiImage: image)
          .resizable()
          .frame(width: width, height: height)
      }
      label
        .frame(width: width - 30 * unit, height: 53 * unit)
        .offset(x: 7 * unit, y: 23 * unit)
    }
    .frame(width: width, height: height, alignment: .topLeading)
  }
}
