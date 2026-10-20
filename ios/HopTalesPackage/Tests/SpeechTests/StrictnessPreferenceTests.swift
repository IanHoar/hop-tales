import Foundation
import Testing

@testable import SpeechRecognition

struct StrictnessPreferenceTests {
  @Test func anUnsetPreferenceIsGentle() {
    #expect(StrictnessPreference.stored(in: UUID().uuidString).load() == .gentle)
  }

  @Test func aSavedPreferenceSurvives() {
    let suite = UUID().uuidString
    StrictnessPreference.stored(in: suite).save(.standard)
    #expect(StrictnessPreference.stored(in: suite).load() == .standard)
  }

  @Test func rubbishInTheStoreFallsBackToGentle() {
    let suite = UUID().uuidString
    UserDefaults(suiteName: suite)?.set("ferocious", forKey: StrictnessPreference.key)
    #expect(StrictnessPreference.stored(in: suite).load() == .gentle)
  }
}
