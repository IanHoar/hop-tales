import Content
import Testing

@testable import SpeechRecognition

struct WordMatcherTests {
  let sat = Word(text: "sat")
  let knight = Word(text: "knight", homophones: ["night"])
  let mat = Word(text: "mat")

  @Test func exactMatch() {
    let match = WordMatcher.match(tokens: ["the", "cat", "sat"], current: sat, next: mat)
    #expect(match?.target == .current)
  }

  @Test func onlyTheLastThreeTokensCount() {
    #expect(WordMatcher.match(tokens: ["sat", "a", "b", "c"], current: sat, next: mat) == nil)
  }

  @Test func levenshteinOneIsAcceptedForLongerWords() {
    #expect(WordMatcher.match(tokens: ["knigh"], current: knight, next: nil)?.target == .current)
  }

  @Test func levenshteinIsNotAppliedToShortWords() {
    #expect(
      WordMatcher.match(tokens: ["sad"], current: sat, next: nil, strictness: .standard) == nil
    )
  }

  @Test func droppedFinalConsonantIsForgivenWhenGentle() {
    #expect(WordMatcher.match(tokens: ["sap"], current: sat, next: nil)?.target == .current)
    #expect(
      WordMatcher.match(tokens: ["sap"], current: sat, next: nil, strictness: .standard) == nil
    )
  }

  @Test func homophonesAreAcceptedWhenGentle() {
    let would = Word(text: "would", homophones: ["wood"])
    #expect(WordMatcher.match(tokens: ["wood"], current: would, next: nil)?.target == .current)
    #expect(
      WordMatcher.match(tokens: ["wood"], current: would, next: nil, strictness: .standard) == nil
    )
    #expect(WordMatcher.match(tokens: ["night"], current: knight, next: nil)?.target == .current)
  }

  @Test func readingAheadMarksTheCurrentWordReadToo() {
    #expect(WordMatcher.match(tokens: ["mat"], current: sat, next: mat)?.target == .next)
  }

  @Test func normalizeStripsPunctuationAndCase() {
    #expect(WordMatcher.normalize("The cat, SAT!") == ["the", "cat", "sat"])
  }

  @Test func partialsMustRepeatBeforeTheyCount() {
    var debouncer = PartialDebouncer()
    #expect(debouncer.confirm(tokens: ["sat"], isFinal: false).isEmpty)
    #expect(debouncer.confirm(tokens: ["sat"], isFinal: false) == ["sat"])
  }

  @Test func finalResultsCountImmediately() {
    var debouncer = PartialDebouncer()
    #expect(debouncer.confirm(tokens: ["sat"], isFinal: true) == ["sat"])
  }
}
