#if DEBUG
import ComposableArchitecture2
import Content
import Dependencies
import DesignSystem
import SpeechRecognition
import SwiftUI

struct SettingsPreview: View {
  var width = Metrics.phone.reference.width
  var height = Metrics.phone.reference.height
  var plus = PlusStatus.free
  var foundNothingToRestore = false

  var body: some View {
    SettingsScreen(store: store)
      .frame(width: width, height: height)
      .environment(\.locale, Locale(identifier: "en_CA"))
      .environment(\.timeZone, TimeZone(identifier: "UTC")!)
  }

  private var state: Settings.State {
    var state = Settings.State()
    state.plusStatus = plus
    state.foundNothingToRestore = foundNothingToRestore
    return state
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
        speak: { _, _, _ in },
        voices: {
          [Voice(id: "samantha", name: "Samantha", language: "en-US")]
        }
      )
      $0[PurchasesClient.self] = .fake(isPlus: plus.canManage, status: plus)
    } operation: {
      Store(initialState: state) { Settings() }
    }
  }
}

struct PlusSectionPreview: View {
  var plus = PlusStatus.free
  var foundNothingToRestore = false

  var body: some View {
    SettingsPreview(
      height: 520, plus: plus, foundNothingToRestore: foundNothingToRestore
    )
  }

  static let renewal = Date(timeIntervalSince1970: 1_772_496_000)
}

#Preview("Settings") { SettingsPreview() }
#Preview("Plus, free") { PlusSectionPreview() }
#Preview("Plus, renews") {
  PlusSectionPreview(
    plus: PlusStatus(.renews(PlusSectionPreview.renewal), refundableTransactionID: 1)
  )
}
#Preview("Plus, payment problem") {
  PlusSectionPreview(plus: PlusStatus(.paymentProblem, refundableTransactionID: 1))
}
#endif
