import Content
import DesignSystem
import SpriteKit
import SwiftUI

public struct WorldView: View {
  let progress: Double
  let mood: Mood
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var scene = MeadowScene(size: CGSize(width: 390, height: 844))

  public init(progress: Double, mood: Mood) {
    self.progress = progress
    self.mood = mood
  }

  public var body: some View {
    SpriteView(scene: scene, preferredFramesPerSecond: 60, options: [.allowsTransparency])
      .onAppear {
        scene.drifts = !reduceMotion
        scene.setMood(mood, animated: false)
        scene.setProgress(progress, animated: false)
      }
      .onChange(of: progress) { _, progress in
        scene.setProgress(progress, animated: !reduceMotion)
      }
      .onChange(of: mood) { _, mood in scene.setMood(mood) }
      .accessibilityHidden(true)
  }
}

#Preview("World") {
  @Previewable @State var progress: Double = 0
  @Previewable @State var mood = Mood()
  WorldView(progress: progress, mood: mood)
    .ignoresSafeArea()
    .overlay(alignment: .bottom) {
      VStack {
        Button("Read a word") { progress += Story.stepPerWord }
        HStack {
          ForEach(Sky.allCases, id: \.self) { sky in
            Button(sky.rawValue) { mood.sky = sky }
          }
        }
        HStack {
          ForEach(Weather.allCases, id: \.self) { weather in
            Button(weather.rawValue) { mood.weather = weather }
          }
        }
      }
      .buttonStyle(.borderedProminent)
      .padding(.bottom, 40)
    }
}

#Preview("Postcards") {
  let moods = [
    Mood(sky: .day), Mood(sky: .golden, weather: .clouds), Mood(sky: .day, weather: .rain),
    Mood(sky: .dusk), Mood(sky: .night)
  ]
  ScrollView {
    VStack(spacing: 8) {
      ForEach(moods, id: \.self) { mood in
        Image(uiImage: MeadowPostcard.image(mood: mood, size: CGSize(width: 390, height: 520)))
          .resizable()
          .scaledToFit()
      }
    }
  }
}

public struct MeadowBackdrop: View {
  let progress: Double
  let mood: Mood
  @Environment(\.freezesMotion) private var freezesMotion

  public init(progress: Double, mood: Mood) {
    self.progress = progress
    self.mood = mood
  }

  public var body: some View {
    GeometryReader { proxy in
      if freezesMotion {
        Image(uiImage: MeadowPostcard.image(mood: mood, size: proxy.size, progress: progress))
          .resizable()
      } else {
        WorldView(progress: progress, mood: mood)
      }
    }
    .ignoresSafeArea()
  }
}
