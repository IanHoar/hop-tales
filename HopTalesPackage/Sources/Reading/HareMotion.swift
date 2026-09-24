import Foundation
import World

struct HareMotion: Equatable {
  struct Pose: Equatable {
    var frame: HareFrame
    var x: CGFloat = 0
    var lift: CGFloat = 0
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1

    static let resting = Pose(frame: .rest)
  }

  struct Hop: Equatable {
    var start: TimeInterval
    var fromX: CGFloat
    var distance: CGFloat
    var carried = false
  }

  struct Beat: Equatable {
    var index: Int
    var hold: TimeInterval
  }

  static let fps: Double = 14
  static let hopFrames = 8
  static let hopLength = Double(hopFrames) / fps
  static let moveFrames = 1...6
  static let ride: TimeInterval = 0.45
  static let apex: CGFloat = 46
  static let sentenceApex: CGFloat = 96
  static let takeOff = Double(moveFrames.lowerBound) / fps
  static let airTime = Double(moveFrames.count) / fps
  static let breath: TimeInterval = 3.8
  static let breathY: CGFloat = 0.014
  static let breathX: CGFloat = 0.006
  static let cycle: TimeInterval = 18
  static let firstBeat: TimeInterval = 2.4
  static let gapVariance = 0.3

  static let blink = [
    Beat(index: 5, hold: 0.05), Beat(index: 3, hold: 0.09), Beat(index: 5, hold: 0.06)
  ]
  static let ear = [
    Beat(index: 6, hold: 0.09), Beat(index: 7, hold: 0.09), Beat(index: 2, hold: 1.1),
    Beat(index: 7, hold: 0.1), Beat(index: 6, hold: 0.1)
  ]
  static let tilt = [
    Beat(index: 8, hold: 0.14), Beat(index: 9, hold: 0.14), Beat(index: 4, hold: 2.6),
    Beat(index: 9, hold: 0.16), Beat(index: 8, hold: 0.16)
  ]
  static let sniff = [Beat(index: 1, hold: 0.5)]
  static let gestures = [blink, ear, tilt, blink, blink, sniff]
  static let gaps: [TimeInterval] = [2.4, 2.0, 1.4, 2.0, 1.6, 0]

  var hop: Hop?

  static func length(_ gesture: [Beat]) -> TimeInterval {
    gesture.reduce(0) { $0 + $1.hold }
  }

  static func schedule(cycle index: Int) -> [(start: TimeInterval, gesture: [Beat])] {
    var random = Scatter(seed: index)
    var order = Array(gestures.indices)
    for slot in order.indices.reversed() {
      order.swapAt(slot, random.below(slot + 1))
    }
    var start = firstBeat * (1 + gapVariance * random.signed())
    var events: [(start: TimeInterval, gesture: [Beat])] = []
    for (slot, gesture) in order.enumerated() {
      let beats = gestures[gesture]
      guard start + length(beats) < cycle else { break }
      events.append((start, beats))
      start += length(beats) + gaps[slot] * (1 + gapVariance * random.signed())
    }
    return events
  }

  static func idleFrame(at time: TimeInterval) -> Int {
    let cycleIndex = Int((time / cycle).rounded(.down))
    let local = time - Double(cycleIndex) * cycle
    for event in schedule(cycle: cycleIndex) where local >= event.start {
      var cursor = event.start
      for beat in event.gesture {
        if local < cursor + beat.hold { return beat.index }
        cursor += beat.hold
      }
    }
    return HareFrame.rest.index
  }

  static func breathing(at time: TimeInterval) -> (x: CGFloat, y: CGFloat) {
    let swell = CGFloat((1 - cos(2 * .pi * time / breath)) / 2)
    return (1 + breathX * swell, 1 + breathY * swell)
  }

  static func eased(_ progress: Double) -> CGFloat {
    let clamped = min(max(progress, 0), 1)
    return CGFloat(clamped * clamped * (3 - 2 * clamped))
  }

  func x(at time: TimeInterval) -> CGFloat {
    guard let hop, !hop.carried else { return 0 }
    let elapsed = time - hop.start
    let frameTime = 1 / Self.fps
    if elapsed < Self.hopLength {
      let moveStart = Double(Self.moveFrames.lowerBound) * frameTime
      let moveLength = Double(Self.moveFrames.count) * frameTime
      return hop.fromX + hop.distance * Self.eased((elapsed - moveStart) / moveLength)
    }
    let landed = hop.fromX + hop.distance
    return landed * (1 - Self.eased((elapsed - Self.hopLength) / Self.ride))
  }

  func lift(at time: TimeInterval) -> CGFloat {
    guard let hop else { return 0 }
    let frameTime = 1 / Self.fps
    let moveStart = Double(Self.moveFrames.lowerBound) * frameTime
    let progress = (time - hop.start - moveStart) / (Double(Self.moveFrames.count) * frameTime)
    guard progress > 0, progress < 1 else { return 0 }
    return (hop.carried ? Self.sentenceApex : Self.apex) * CGFloat(sin(.pi * progress))
  }

  func pose(at time: TimeInterval, reduceMotion: Bool) -> Pose {
    guard !reduceMotion else { return .resting }
    if let hop, time - hop.start < Self.hopLength, time >= hop.start {
      let index = min(Int((time - hop.start) * Self.fps), Self.hopFrames - 1)
      return Pose(frame: HareFrame(.hop, index), x: x(at: time), lift: lift(at: time))
    }
    let breath = Self.breathing(at: time)
    return Pose(
      frame: HareFrame(.idle, Self.idleFrame(at: time)),
      x: x(at: time),
      scaleX: breath.x,
      scaleY: breath.y
    )
  }

  @discardableResult
  mutating func jump(at time: TimeInterval, distance: CGFloat, carried: Bool) -> TimeInterval {
    hop = Hop(start: time, fromX: carried ? 0 : x(at: time), distance: distance, carried: carried)
    return Self.hopLength
  }
}

private struct Scatter {
  var state: UInt64

  init(seed: Int) {
    state = UInt64(bitPattern: Int64(seed)) &* 0x9E37_79B9_7F4A_7C15 &+ 0x2545_F491_4F6C_DD1D
  }

  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var value = state
    value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
    value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
    return value ^ (value >> 31)
  }

  mutating func below(_ bound: Int) -> Int { Int(next() % UInt64(bound)) }

  mutating func signed() -> Double { Double(next() % 20_001) / 10_000 - 1 }
}
