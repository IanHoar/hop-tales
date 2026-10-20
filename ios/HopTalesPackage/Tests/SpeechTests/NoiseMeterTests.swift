import Foundation
import Testing

@testable import SpeechRecognition

struct NoiseMeterTests {
  private func block(_ meter: NoiseMeter, decibels: Double) {
    let meanSquare = pow(10, decibels / 10)
    meter.add(squares: meanSquare * 100, frames: 100, blockFrames: 100)
  }

  @Test func silenceReadsAsTheFloorOfTheScale() {
    #expect(NoiseMeter().floor == NoiseMeter.silent)
  }

  @Test func theFloorIsTheSteadyBackgroundNotTheSpeech() {
    let meter = NoiseMeter()
    for index in 0..<NoiseMeter.window {
      block(meter, decibels: index.isMultiple(of: 3) ? -20 : -55)
    }
    #expect(abs(meter.floor - -55) < 0.5)
  }

  @Test func aSteadyNoisyRoomRaisesTheFloor() {
    let meter = NoiseMeter()
    for _ in 0..<NoiseMeter.window { block(meter, decibels: -35) }
    #expect(abs(meter.floor - -35) < 0.5)
  }

  @Test func onlyTheLastFewSecondsCount() {
    let meter = NoiseMeter()
    for _ in 0..<NoiseMeter.window { block(meter, decibels: -30) }
    for _ in 0..<NoiseMeter.window { block(meter, decibels: -60) }
    #expect(abs(meter.floor - -60) < 0.5)
  }
}
