import SpriteKit
import SwiftUI

public struct WorldView: View {
  let progress: Double
  @State private var scene = WorldScene(size: CGSize(width: 1, height: 1))

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

#Preview("World") {
  @Previewable @State var progress: Double = 0
  WorldView(progress: progress)
    .ignoresSafeArea()
    .overlay(alignment: .bottom) {
      HStack {
        Button("Read a word") { progress += 60 }
        Button("Castle") { progress = 1000 }
        Button("Start") { progress = 0 }
      }
      .buttonStyle(.borderedProminent)
      .padding(.bottom, 40)
    }
}
