import SpriteKit
import SwiftUI

public struct WorldView: View {
  let progress: Double
  @State private var scene = WorldScene(size: WorldMetrics.size)

  public init(progress: Double) {
    self.progress = progress
  }

  public var body: some View {
    SpriteView(scene: scene, preferredFramesPerSecond: 60, options: [.allowsTransparency])
      .onAppear { scene.setProgress(progress, animated: false) }
      .onChange(of: progress) { _, progress in scene.setProgress(progress) }
      .accessibilityHidden(true)
  }
}
