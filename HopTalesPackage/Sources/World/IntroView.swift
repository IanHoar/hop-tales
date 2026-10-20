import DesignSystem
import SpriteKit
import SwiftUI

public struct IntroView: View {
  static let launchImage = UIImage(named: "LaunchImage", in: .main, with: nil)
  static let wideLaunchImage = UIImage(named: "LaunchImageWide", in: .main, with: nil)

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @State private var scene: IntroScene?
  @State private var hasDrawn = false
  @State private var screen = CGSize.zero

  public init() {}

  public var body: some View {
    Color(hex: 0x1E2A4E)
      .overlay(alignment: .bottomLeading) {
        if !hasDrawn, let image = launchImage {
          let size = IntroLayout.launchSize(image.size, filling: screen)
          Image(uiImage: image)
            .resizable()
            .frame(width: size.width, height: size.height)
        }
      }
      .overlay {
        if let scene {
          SpriteView(scene: scene, preferredFramesPerSecond: 60, options: [.allowsTransparency])
            .opacity(hasDrawn ? 1 : 0)
        }
      }
      .onGeometryChange(for: CGSize.self, of: \.size) { size in
        screen = size
        guard scene == nil, size.width > 0, size.height > 0 else { return }
        let scene = IntroScene(size: size, launchImage: launchImage)
        scene.onFirstFrame = { hasDrawn = true }
        if !reduceMotion { scene.play() }
        self.scene = scene
      }
      .ignoresSafeArea()
      .accessibilityHidden(true)
  }

  private var launchImage: UIImage? {
    horizontalSizeClass == .regular ? Self.wideLaunchImage : Self.launchImage
  }
}

#Preview {
  IntroView()
}
