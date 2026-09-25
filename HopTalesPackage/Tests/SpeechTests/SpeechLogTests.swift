import Foundation
import Testing

@testable import SpeechRecognition

struct SpeechLogTests {
  private func entry(_ heard: String, outcome: SpeechLogEntry.Outcome = .none) -> SpeechLogEntry {
    SpeechLogEntry(
      date: Date(timeIntervalSince1970: 0),
      story: "meadow-walk",
      sentence: 1,
      word: "sat",
      heard: heard.split(separator: " ").map(String.init),
      isFinal: false,
      outcome: outcome
    )
  }

  @Test func nothingIsKeptUntilTheLogIsSwitchedOn() {
    let log = SpeechLog.inMemory(suiteName: UUID().uuidString)
    log.record(entry("set"))
    #expect(log.entries().isEmpty)
    log.setEnabled(true)
    log.record(entry("set"))
    #expect(log.entries().count == 1)
  }

  @Test func clearingEmptiesTheLog() {
    let log = SpeechLog.inMemory(suiteName: UUID().uuidString)
    log.setEnabled(true)
    log.record(entry("sad"))
    log.clear()
    #expect(log.entries().isEmpty)
  }

  @Test func theExportIsOneLinePerResult() {
    let csv = SpeechLog.csv([entry("the hare sat", outcome: .current)])
    #expect(csv == """
      time,story,sentence,word,heard,kind,outcome
      1970-01-01T00:00:00.000Z,meadow-walk,1,sat,the hare sat,partial,current

      """)
  }
}
