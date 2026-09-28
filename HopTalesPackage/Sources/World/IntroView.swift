import DesignSystem
import SpriteKit
import SwiftUI

public struct IntroView: View {
  static let launchImage = UIImage(named: "LaunchImage", in: .main, with: nil)

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var scene: IntroScene?
  @State private var hasDrawn = false

  public init() {}

  public var body: some View {
    Color(hex: 0x1E2A4E)
      .overlay(alignment: .bottomLeading) {
        if !hasDrawn, let image = Self.launchImage {
          Image(uiImage: image)
        }
      }
      .overlay {
        if let scene {
          SpriteView(scene: scene, preferredFramesPerSecond: 60, options: [.allowsTransparency])
            .opacity(hasDrawn ? 1 : 0)
        }
      }
      .onGeometryChange(for: CGSize.self, of: \.size) { size in
        guard scene == nil, size.width > 0, size.height > 0 else { return }
        let scene = IntroScene(size: size, launchImage: Self.launchImage)
        scene.onFirstFrame = { hasDrawn = true }
        if !reduceMotion { scene.play() }
        self.scene = scene
      }
      .ignoresSafeArea()
      .accessibilityHidden(true)
  }
}

#Preview {
  IntroView()
}
