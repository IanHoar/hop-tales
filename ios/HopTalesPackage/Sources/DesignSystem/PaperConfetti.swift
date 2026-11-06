import SwiftUI

public struct PaperConfetti: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var fallen = false
  let size: CGSize
  let delay: Double

  public init(size: CGSize, delay: Double = 0) {
    self.size = size
    self.delay = delay
  }

  private static let colours: [Color] = [
    Paper.red, Paper.wash, Paper.sage, Color(hex: 0x8FB7D9), Color(hex: 0xE8A7B8)
  ]

  public var body: some View {
    ZStack {
      ForEach(0..<36, id: \.self) { index in
        let x = CGFloat((index * 37) % 100) / 100 * size.width
        RoundedRectangle(cornerRadius: 1.5)
          .fill(Self.colours[index % Self.colours.count])
          .frame(width: 7, height: 11)
          .rotationEffect(.degrees(fallen ? Double(index * 47) : 0))
          .position(
            x: x + (fallen ? CGFloat(index % 7 - 3) * 14 : 0),
            y: fallen ? size.height * (0.35 + CGFloat(index % 9) * 0.06) : -20
          )
          .opacity(fallen ? 0 : 1)
      }
    }
    .frame(width: size.width, height: size.height)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
    .onAppear {
      guard !reduceMotion else { return }
      withAnimation(.easeIn(duration: 2.2).delay(delay)) { fallen = true }
    }
  }
}
