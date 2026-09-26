import Testing

@testable import World

struct IdleMotionTests {
  @Test func heRestsMostOfTheTimeAndStillBlinksAndTwitches() {
    let samples = stride(from: 0.0, to: IdleMotion.cycle, by: 0.02).map(IdleMotion.frame(at:))
    let resting = samples.filter { $0 == HareFrame.rest.index }.count
    #expect(Double(resting) / Double(samples.count) > 0.5)
    #expect(samples.contains(3))
    #expect(Set(samples).count > 3)
  }

  @Test func everyCycleShufflesItsGesturesAndFitsInEighteenSeconds() {
    let first = IdleMotion.schedule(cycle: 0).map(\.gesture)
    let second = IdleMotion.schedule(cycle: 1).map(\.gesture)
    #expect(first != second)
    for index in 0..<20 {
      for event in IdleMotion.schedule(cycle: index) {
        #expect(event.start + IdleMotion.length(event.gesture) < IdleMotion.cycle)
      }
    }
    let again = IdleMotion.schedule(cycle: 3).map(\.start)
    #expect(IdleMotion.schedule(cycle: 3).map(\.start) == again)
  }

  @Test func heBreathesGentlyFromTheFeet() {
    let rest = IdleMotion.breathing(at: 0)
    let full = IdleMotion.breathing(at: IdleMotion.breath / 2)
    #expect(rest.x == 1 && rest.y == 1)
    #expect(abs(full.y - 1.014) < 0.0001)
    #expect(abs(full.x - 1.006) < 0.0001)
  }
}
