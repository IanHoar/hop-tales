import Testing

@testable import Reading

struct ChordTests {
  @Test func itRendersTheWholeChordWithoutClipping() throws {
    let buffer = try #require(Chord.buffer())
    let samples = try #require(buffer.floatChannelData?[0])
    let frames = Int(buffer.frameLength)
    #expect(frames == Int(Chord.length * Chord.sampleRate))
    let peak = (0..<frames).map { abs(samples[$0]) }.max() ?? 0
    #expect(peak > 0.1)
    #expect(peak < 1)
  }

  @Test func eachNoteComesInAfterTheOneBelow() {
    #expect(Chord.sample(at: 0) == 0)
    let early = (0..<40).map { abs(Chord.sample(at: Double($0) / Chord.sampleRate * 40)) }
    #expect(early.contains { $0 > 0 })
  }

  @Test func itDiesAwayBeforeItEnds() {
    let tail = stride(from: Chord.length - 0.05, to: Chord.length, by: 0.001).map {
      abs(Chord.sample(at: $0))
    }
    #expect((tail.max() ?? 1) < 0.02)
  }
}
