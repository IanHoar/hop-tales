import SwiftUI
import Testing

@testable import Reading

/// The hop is ballistic rather than eased, which is the one place the app deliberately departs from
/// `docs/HANDOFF.md` §4. These pin the physics so it cannot drift back into a float.
@MainActor
struct HopTests {
  let timeline = KeyframeTimeline(initialValue: Hop()) { Hop.track(squash: true) }
  let reduced = KeyframeTimeline(initialValue: Hop()) { Hop.track(squash: false) }

  @Test func oneCycleKeepsTheSpecPeriod() {
    // 0.33 up + 0.33 down + a 0.06 beat on the ground.
    #expect(abs(timeline.duration - 0.72) < 0.0001)
  }

  @Test func itLeavesTheGroundReachesTheApexAndComesBack() {
    #expect(timeline.value(time: 0).y == 0)
    #expect(abs(timeline.value(time: 0.33).y - 1) < 0.0001)
    #expect(abs(timeline.value(time: 0.66).y) < 0.0001)
  }

  @Test func itRestsOnTheGroundBetweenHops() {
    // Without this beat the hops run together and read as a sine wave.
    #expect(timeline.value(time: 0.70).y == 0)
  }

  @Test func itIsFastestOffTheGroundAndSlowestAtTheApex() {
    let launch = timeline.value(time: 0.04).y - timeline.value(time: 0).y
    let apex = timeline.value(time: 0.33).y - timeline.value(time: 0.29).y
    #expect(launch > apex * 2)
  }

  @Test func theFallMirrorsTheRise() {
    // Gravity is symmetric: the same height on the way up and the way down.
    for offset in stride(from: 0.03, through: 0.30, by: 0.03) {
      let rising = timeline.value(time: 0.33 - offset).y
      let falling = timeline.value(time: 0.33 + offset).y
      #expect(abs(rising - falling) < 0.02)
    }
  }

  @Test func theBallSquashesOnContactAndStretchesOnTheRise() {
    #expect(timeline.value(time: 0.33).scaleY > 1)  // stretched climbing
    #expect(timeline.value(time: 0.66).scaleY < 1)  // squashed on contact
    #expect(timeline.value(time: 0.66).scaleX > 1)  // and wider for it
  }

  @Test func reduceMotionKeepsTheBallUnsquashed() {
    for time in stride(from: 0.0, through: 0.72, by: 0.04) {
      #expect(reduced.value(time: time).scaleX == 1)
      #expect(reduced.value(time: time).scaleY == 1)
    }
  }
}
