import SwiftUI
import Testing

@testable import Reading
@MainActor
struct HopTests {
  let timeline = KeyframeTimeline(initialValue: Hop()) { Hop.track(squash: true) }
  let reduced = KeyframeTimeline(initialValue: Hop()) { Hop.track(squash: false) }

  @Test func oneCycleKeepsTheSpecPeriod() {
    #expect(abs(timeline.duration - 0.72) < 0.0001)
  }

  @Test func itLeavesTheGroundReachesTheApexAndComesBack() {
    #expect(timeline.value(time: 0).y == 0)
    #expect(abs(timeline.value(time: 0.33).y - 1) < 0.0001)
    #expect(abs(timeline.value(time: 0.66).y) < 0.0001)
  }

  @Test func itRestsOnTheGroundBetweenHops() {
    #expect(timeline.value(time: 0.70).y == 0)
  }

  @Test func itIsFastestOffTheGroundAndSlowestAtTheApex() {
    let launch = timeline.value(time: 0.04).y - timeline.value(time: 0).y
    let apex = timeline.value(time: 0.33).y - timeline.value(time: 0.29).y
    #expect(launch > apex * 2)
  }

  @Test func theFallMirrorsTheRise() {
    for offset in stride(from: 0.03, through: 0.30, by: 0.03) {
      let rising = timeline.value(time: 0.33 - offset).y
      let falling = timeline.value(time: 0.33 + offset).y
      #expect(abs(rising - falling) < 0.02)
    }
  }

  @Test func theBallSquashesOnContactAndStretchesOnTheRise() {
    #expect(timeline.value(time: 0.33).scaleY > 1)
    #expect(timeline.value(time: 0.66).scaleY < 1)
    #expect(timeline.value(time: 0.66).scaleX > 1)
  }

  @Test func reduceMotionKeepsTheBallUnsquashed() {
    for time in stride(from: 0.0, through: 0.72, by: 0.04) {
      #expect(reduced.value(time: time).scaleX == 1)
      #expect(reduced.value(time: time).scaleY == 1)
    }
  }
}
