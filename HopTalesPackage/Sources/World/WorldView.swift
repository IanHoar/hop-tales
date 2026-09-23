import SpriteKit
import SwiftUI

public struct WorldView: View {
  let progress: Double
  var finale = false
  @State private var scene = WorldScene(size: CGSize(width: 1, height: 1))

  public init(progress: Double, finale: Bool = false) {
    self.progress = progress
    self.finale = finale
  }

  public var body: some View {
    SpriteView(scene: scene, preferredFramesPerSecond: 60, options: [.allowsTransparency])
      .onAppear { scene.setProgress(progress, animated: false) }
      .onChange(of: progress) { _, progress in scene.setProgress(progress) }
      .onChange(of: finale) { _, finale in if finale { scene.roar() } }
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

#Preview("World art") {
  let tones = WorldArt.Tone.allCases
  VStack(spacing: 8) {
    ForEach(tones, id: \.self) { tone in
      ZStack {
        ForEach(WorldArt.Layer.allCases, id: \.self) { layer in
          if let image = WorldArt(layer, tone).image(width: 1170) {
            Image(uiImage: image).resizable().scaledToFit()
          }
        }
      }
    }
  }
  .padding(8)
}
