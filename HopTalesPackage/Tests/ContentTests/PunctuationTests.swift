import Foundation
import Testing

@testable import Content

struct PunctuationTests {
  @Test func everyWordTheMatcherSeesIsBare() {
    let words = StoryLibrary.all.flatMap(\.sentences).flatMap(\.words)
    #expect(words.allSatisfy { $0.text.allSatisfy(\.isLetter) })
  }

  @Test func everySentenceEndsInAMark() {
    for sentence in StoryLibrary.all.flatMap(\.sentences) {
      #expect(sentence.words.last?.trailing.contains { ".!?".contains($0) } == true)
    }
  }

  @Test func speechMarksHangOffTheWordsTheyWrap() throws {
    let words = try #require(StoryLibrary["hare-and-frog"]).sentences.flatMap(\.words)
    let can = try #require(words.first { $0.text == "Can" })
    let swim = try #require(words.first { $0.text == "swim" })
    #expect(can.leading == "“")
    #expect(swim.trailing == "?”")
  }

  @Test func aWordWithoutPunctuationRoundTripsWithoutIt() throws {
    let data = try JSONEncoder().encode(Word(text: "sun"))
    let json = try #require(String(data: data, encoding: .utf8))
    #expect(!json.contains("leading") && !json.contains("trailing"))
    #expect(try JSONDecoder().decode(Word.self, from: data).trailing.isEmpty)
  }
}
