import Content
import Testing

@testable import SpeechRecognition

/// These encode the tolerance rules in `HANDOFF.md` §5. They must stay green — they are the only
/// place the matcher can be tuned without a microphone and a five-year-old.
struct WordMatcherTests {
  let sat = Word(text: "sat")
  let knight = Word(text: "knight", homophones: ["night"])
  let mat = Word(text: "mat")

  @Test func exactMatch() {
    #expect(WordMatcher.match(tokens: ["the", "cat", "sat"], current: sat, next: mat)?.target == .current)
  }

  @Test func onlyTheLastThreeTokensCount() {
    #expect(WordMatcher.match(tokens: ["sat", "a", "b", "c"], current: sat, next: mat) == nil)
  }

  @Test func levenshteinOneIsAcceptedForLongerWords() {
    #expect(WordMatcher.match(tokens: ["knigh"], current: knight, next: nil)?.target == .current)
  }

  @Test func levenshteinIsNotAppliedToShortWords() {
    // "sad" is one edit from "sat", but three-letter words are too easy to confuse.
    #expect(WordMatcher.match(tokens: ["sad"], current: sat, next: nil) == nil)
  }

  @Test func droppedFinalConsonantIsForgivenWhenGentle() {
    // Same length, same first two letters — early readers garble final consonants.
    #expect(WordMatcher.match(tokens: ["sap"], current: sat, next: nil)?.target == .current)
    #expect(
      WordMatcher.match(tokens: ["sap"], current: sat, next: nil, strictness: .standard) == nil
    )
  }

  @Test func homophonesAreAcceptedWhenGentle() {
    #expect(WordMatcher.match(tokens: ["night"], current: knight, next: nil)?.target == .current)
    #expect(
      WordMatcher.match(tokens: ["night"], current: knight, next: nil, strictness: .standard) == nil
    )
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
