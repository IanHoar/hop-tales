#if DEBUG
import ComposableArchitecture2
import Content
import Dependencies
import DesignSystem
import SpeechRecognition
import SwiftUI

struct SettingsPreview: View {
  var height = Metrics.phone.reference.height

  var body: some View {
    SettingsScreen(store: store)
      .frame(width: Metrics.phone.reference.width, height: height)
  }

  private var store: StoreOf<Settings> {
    withDependencies {
      $0[ProfileStore.self] = ProfileStore(
        load: { Profile(childName: "Wren", accent: .canadian) },
        save: { _ in }
      )
      $0[StrictnessPreference.self] = StrictnessPreference(load: { .gentle }, save: { _ in })
      $0[SoundPreference.self] = SoundPreference(load: { true }, save: { _ in })
      $0[SpeechClient.self] = SpeechClient(
        listen: { _, _ in AsyncStream { $0.finish() } },
        requestAuthorization: { _ in .authorized },
        speak: { _, _ in },
        voices: {
          [Voice(id: "samantha", name: "Samantha", language: "en-US")]
        }
      )
    } operation: {
      Store(initialState: Settings.State()) { Settings() }
    }
  }
}

#Preview("Settings") { SettingsPreview() }
#endif
