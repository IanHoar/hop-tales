import Content
import CoreGraphics
import DesignSystem
import Testing

@testable import Reading
@MainActor
struct WordRowTests {
  static let phone = ReadingGeometry(size: CGSize(width: 390, height: 844))

  @Test func wordStatesFollowTheirDistanceFromTheCurrentWord() {
    #expect(WordDisplayState(offsetFromCurrent: -2) == .completed)
    #expect(WordDisplayState(offsetFromCurrent: -1) == .completed)
    #expect(WordDisplayState(offsetFromCurrent: 0) == .current)
    #expect(WordDisplayState(offsetFromCurrent: 1) == .next)
    #expect(WordDisplayState(offsetFromCurrent: 2) == .upcoming)
  }

  @Test func theReferencePhoneNeedsNoScaling() {
    let geometry = Self.phone
    #expect(geometry.scale == 1)
    #expect(geometry.cardSize == CGSize(width: 358, height: 196))

    #expect(geometry.cardCenter == CGPoint(x: 195, y: 550))
    #expect(geometry.currentWordSize == 64)
    #expect(geometry.sideWordSize == 22)
  }

  @Test func widthsScaleWithTheScreenAndHeightsStayProportional() {
    let wide = ReadingGeometry(size: CGSize(width: 780, height: 1688))
    #expect(wide.scale == 2)
    #expect(wide.cardSize == CGSize(width: 716, height: 392))
    #expect(wide.currentWordSize == 128)

    #expect(wide.y(422) == 844)
  }

  @Test func shortWordsKeepTheFullSize() {
    let words = [Word(text: "The"), Word(text: "cat"), Word(text: "sat")]
    let size = WordRow.currentSize(words: words, currentIndex: 1, geometry: Self.phone)
    #expect(size == Self.phone.currentWordSize)
  }

  @Test func longWordsShrinkTheWordAndNotTheCard() {
    let words = [Word(text: "the"), Word(text: "extraordinarily"), Word(text: "long")]
    let size = WordRow.currentSize(words: words, currentIndex: 1, geometry: Self.phone)
    #expect(size < Self.phone.currentWordSize)

    #expect(size >= Self.phone.currentWordSize / 2)
    #expect(Self.phone.cardSize.width == 358)
  }

  @Test func onlyTheNeighbouringWordsCompeteForTheSpace() {
    let short = [Word(text: "a"), Word(text: "knight"), Word(text: "b")]
    let longTail = short + [Word(text: "extraordinarily"), Word(text: "longer")]
    #expect(
      WordRow.currentSize(words: short, currentIndex: 1, geometry: Self.phone)
        == WordRow.currentSize(words: longTail, currentIndex: 1, geometry: Self.phone)
    )
  }
}
