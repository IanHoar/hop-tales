import Testing

@testable import SpeechRecognition

struct VoiceChoiceTests {
  static let samantha = VoiceCandidate(
    id: "samantha", name: "Samantha", language: "en-US", quality: 2
  )
  static let daniel = VoiceCandidate(id: "daniel", name: "Daniel", language: "en-GB", quality: 1)
  static let serena = VoiceCandidate(id: "serena", name: "Serena", language: "en-GB", quality: 3)
  static let karen = VoiceCandidate(id: "karen", name: "Karen", language: "en_AU", quality: 1)
  static let thomas = VoiceCandidate(id: "thomas", name: "Thomas", language: "fr-FR", quality: 3)
  static let bubbles = VoiceCandidate(
    id: "bubbles", name: "Bubbles", language: "en-GB", quality: 3, isNovelty: true
  )

  @Test func theAccentsOwnVoiceComesFirst() {
    let voices = [Self.samantha, Self.daniel, Self.thomas]
    #expect(VoiceChoice.best(voices, accent: "en-GB") == Self.daniel)
  }

  @Test func theFinestVoiceOfTheAccentWins() {
    let voices = [Self.samantha, Self.daniel, Self.serena]
    #expect(VoiceChoice.best(voices, accent: "en-GB") == Self.serena)
  }

  @Test func underscoresAndCaseStillMatchTheAccent() {
    let voices = [Self.samantha, Self.karen]
    #expect(VoiceChoice.best(voices, accent: "EN-au") == Self.karen)
  }

  @Test func withoutAnAccentVoiceSamanthaStillLeads() {
    let voices = [Self.daniel, Self.serena, Self.samantha]
    #expect(VoiceChoice.best(voices, accent: "en-CA") == Self.samantha)
  }

  @Test func withoutSamanthaTheFinestEnglishVoiceLeads() {
    let voices = [Self.daniel, Self.serena, Self.thomas]
    #expect(VoiceChoice.best(voices, accent: "en-CA") == Self.serena)
  }

  @Test func noveltyAndOtherLanguagesAreNeverChosen() {
    #expect(VoiceChoice.best([Self.bubbles, Self.thomas], accent: "en-GB") == nil)
  }
}
