import Content
import Foundation
import Testing

@testable import Reading

struct CompanionPropTests {
  private let story = StoryLibrary["meadow-walk"]!
  private let start = Date(timeIntervalSince1970: 0)

  private var met: HopTarget {
    HopTarget(sentence: companion.sentence + 1, word: 0)
  }

  private var companion: PropKey {
    let sentence = story.sentences.firstIndex { $0.events.contains(where: \.isCompanion) }!
    let index = story.sentences[sentence].events.firstIndex(where: \.isCompanion)!
    return PropKey(sentence: sentence, index: index)
  }

  @Test func theMeadowWalksBugRunsAlongsideBob() {
    #expect(story.sentences[companion.sentence].events[companion.index].prop == "bug")
  }

  @Test func aCompanionNamedByItsSentencesLastWordArrivesAsTheNextBegins() {
    let cues = PropTiming.cues([:], story: story, at: met, now: start)
    #expect(cues[companion] != nil)
    #expect(cues[companion]?.ended == nil)
  }

  @Test func aCompanionKeepsRunningThroughTheSentencesAfter() {
    var cues = PropTiming.cues([:], story: story, at: met, now: start)
    let later = HopTarget(sentence: story.sentences.count - 1, word: 0)
    cues = PropTiming.cues(cues, story: story, at: later, now: start.addingTimeInterval(9))
    #expect(cues[companion]?.ended == nil)
  }

  @Test func aCompanionDashesOffWhenTheStoryEnds() {
    var cues = PropTiming.cues([:], story: story, at: met, now: start)
    let end = HopTarget(sentence: story.sentences.count, word: 0)
    cues = PropTiming.cues(cues, story: story, at: end, now: start.addingTimeInterval(5))
    #expect(cues[companion]?.ended == start.addingTimeInterval(5))
  }

  @Test func theDashCarriesItPastTheTrailingEdge() {
    let width: CGFloat = 400
    let running = PropPose.running(time: 5, exit: 0, width: width, unit: 1)
    let gone = PropPose.running(time: 5, exit: 1, width: width, unit: 1)
    #expect(running.flip)
    #expect(abs(running.dx) < 1)
    #expect(gone.dx >= width)
  }
}
