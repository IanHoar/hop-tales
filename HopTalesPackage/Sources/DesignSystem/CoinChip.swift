import SwiftUI

public struct CoinChip: View {
  let count: Int
  var height: CGFloat = 52

  public init(count: Int, height: CGFloat = 52) {
    self.count = count
    self.height = height
  }

  public var body: some View {
    HStack(spacing: height * 0.15) {
      Coin(size: height * 0.73)
      Text("\(count)")
        .font(Typography.display(height * 0.42))
        .foregroundStyle(Palette.ink)
        .monospacedDigit()
    }
    .padding(.leading, height * 0.12)
    .padding(.trailing, height * 0.3)
    .frame(height: height)
    .parchmentBevel(Capsule())
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(count) stars")
  }
}
