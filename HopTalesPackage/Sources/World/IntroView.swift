import DesignSystem
import SpriteKit
import SwiftUI

public struct IntroView: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var scene = IntroScene(
    size: CGSize(width: 390, height: 844),
    launchImage: UIImage(named: "LaunchImage", in: .main, with: nil)
  )

  public init() {}

  public var body: some View {
    SpriteView(scene: scene, preferredFramesPerSecond: 60, options: [.allowsTransparency])
      .background(Color(hex: 0x1E2A4E))
      .onAppear {
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
