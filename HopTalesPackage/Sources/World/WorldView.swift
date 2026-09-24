import Content
import DesignSystem
import SpriteKit
import SwiftUI

public struct WorldView: View {
  let progress: Double
  let camera: MeadowCamera?
  let framing: MeadowFraming
  let mood: Mood
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var scene = MeadowScene(size: CGSize(width: 390, height: 844))

  public init(progress: Double, mood: Mood) {
    self.progress = progress
    self.mood = mood
    camera = nil
    framing = .wide
  }

  public init(camera: MeadowCamera, mood: Mood, framing: MeadowFraming) {
    self.camera = camera
    self.mood = mood
    self.framing = framing
    progress = Double(camera.to)
  }

  public var body: some View {
    SpriteView(scene: scene, preferredFramesPerSecond: 60, options: [.allowsTransparency])
      .onAppear {
        scene.drifts = !reduceMotion
        scene.framing = framing
        scene.setMood(mood, animated: false)
        if let camera {
          scene.setCamera(camera)
        } else {
          scene.setProgress(progress, animated: false)
        }
      }
      .onChange(of: progress) { _, progress in
        guard camera == nil else { return }
        scene.setProgress(progress, animated: !reduceMotion)
      }
      .onChange(of: camera) { _, camera in
        if let camera { scene.setCamera(camera) }
      }
      .onChange(of: framing) { _, framing in scene.framing = framing }
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
  public static let stillCrossfade = Animation.easeInOut(duration: 0.2)

  let progress: Double
  let camera: MeadowCamera?
  let framing: MeadowFraming
  let mood: Mood
  @Environment(\.freezesMotion) private var freezesMotion
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  public init(progress: Double, mood: Mood) {
    self.progress = progress
    self.mood = mood
    camera = nil
    framing = .wide
  }

  public init(camera: MeadowCamera, mood: Mood, framing: MeadowFraming) {
    self.camera = camera
    self.mood = mood
    self.framing = framing
    progress = Double(camera.to)
  }

  private func postcard(_ size: CGSize) -> some View {
    Image(
      uiImage: MeadowPostcard.image(mood: mood, size: size, progress: progress, framing: framing)
    )
    .resizable()
  }

  public var body: some View {
    GeometryReader { proxy in
      if freezesMotion {
        postcard(proxy.size)
      } else if camera != nil, reduceMotion {
        ZStack {
          postcard(proxy.size)
            .id(progress)
            .transition(.opacity)
        }
        .animation(Self.stillCrossfade, value: progress)
      } else if let camera {
        WorldView(camera: camera, mood: mood, framing: framing)
      } else {
        WorldView(progress: progress, mood: mood)
      }
    }
    .ignoresSafeArea()
  }
}
