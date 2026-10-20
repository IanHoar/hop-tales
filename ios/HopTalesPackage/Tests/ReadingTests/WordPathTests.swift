import Content
import CoreGraphics
import DesignSystem
import Testing

@testable import Reading

@MainActor
struct WordPathTests {
  static let phone = ReadingGeometry(size: CGSize(width: 390, height: 844))
  static let story = StoryLibrary.all[0]

  var path: WordPath {
    WordPath(sentences: Self.story.sentences.map(\.words), geometry: Self.phone)
  }

  @Test func neighbouringWordsSitSixtyFourPointsApart() {
    let first = path.stops[0]
    let second = path.stops[1]
    let gap = second.centre - first.centre - first.width / 2 - second.width / 2
    #expect(abs(gap - WordPath.gap) < 0.001)
  }

  @Test func aNewSentenceLeavesALongerGap() throws {
    let start = try #require(path.stops.firstIndex { $0.target == HopTarget(sentence: 1, word: 0) })
    let before = path.stops[start - 1]
    let after = path.stops[start]
    let gap = after.centre - before.centre - before.width / 2 - after.width / 2
    #expect(abs(gap - WordPath.sentenceGap) < 0.001)
  }

  @Test func theCurrentWordSitsAtTheFocus() {
    let target = HopTarget(sentence: 0, word: 2)
    let stop = path.stop(at: target)
    #expect(path.camera(at: HopTarget(sentence: 0, word: 0)) == 0)
    #expect(stop.map { $0.centre - path.camera(at: target) } == WordPath.focusX)
  }

  @Test func theEndOvershootsTheLastWordTowardsTheSign() throws {
    let last = try #require(path.stops.last)
    let end = path.camera(at: HopTarget(sentence: Self.story.sentences.count, word: 0))
    #expect(abs(end - (last.centre + WordPath.overshoot - WordPath.focusX)) < 0.001)
    #expect(path.endSign - last.centre == WordPath.endSign)
    #expect(path.startSign - path.stops[0].centre == WordPath.startSign)
  }

  @Test func thePathSitsLowOnTheReferencePhone() {
    #expect(Self.phone.pathCentre == 640)
    #expect(path.hareFeetY == 670)
    #expect(path.signFeetY == 600)
  }

  @Test func theIPadDrawsThePathLarger() {
    let pad = ReadingGeometry(metrics: .pad, size: CGSize(width: 1194, height: 834))
    let padPath = WordPath(sentences: Self.story.sentences.map(\.words), geometry: pad)
    #expect(padPath.wordSize > path.wordSize)
    #expect(abs(pad.pathCentre / 834 - Self.phone.pathCentre / 844) < 0.01)
  }

  @Test func wordsBehindTheHareAreRead() {
    let position = HopTarget(sentence: 1, word: 1)
    #expect(WordPath.state(of: HopTarget(sentence: 0, word: 4), at: position) == .read)
    #expect(WordPath.state(of: HopTarget(sentence: 1, word: 0), at: position) == .read)
    #expect(WordPath.state(of: position, at: position) == .current)
    #expect(WordPath.state(of: HopTarget(sentence: 1, word: 2), at: position) == .upcoming)
  }
}
