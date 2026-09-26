import DesignSystem
import SpriteKit
import SwiftUI

public struct IntroView: View {
  static let launchImage = UIImage(named: "LaunchImage", in: .main, with: nil)

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var scene = IntroScene(
    size: CGSize(width: 390, height: 844),
    launchImage: Self.launchImage
  )
  @State private var hasDrawn = false

  public init() {}

  public var body: some View {
    ZStack(alignment: .bottomLeading) {
      Color(hex: 0x1E2A4E)
      if !hasDrawn, let image = Self.launchImage {
        Image(uiImage: image)
      }
      SpriteView(scene: scene, preferredFramesPerSecond: 60, options: [.allowsTransparency])
        .opacity(hasDrawn ? 1 : 0)
    }
    .onAppear {
      scene.onFirstFrame = { hasDrawn = true }
      guard !reduceMotion else { return }
      scene.play()
    }
    .ignoresSafeArea()
    .accessibilityHidden(true)
  }
}

#Preview {
  IntroView()
}
