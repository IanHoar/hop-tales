import Dependencies
import Foundation

public struct GateQuestion: Equatable, Sendable {
  public static let factors = 3...9
  public static let answerDigits = 2

  static let names = [
    "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"
  ]

  public var left: Int
  public var right: Int

  public init(left: Int, right: Int) {
    self.left = left
    self.right = right
  }

  public var answer: Int { left * right }

  public var words: String {
    "What is \(Self.names[left]) times \(Self.names[right])?"
  }

  public func accepts(_ entry: String) -> Bool {
    Int(entry) == answer
  }

  public static func drawn(seed: UInt64, round: Int) -> GateQuestion {
    var draw = GateDraw(seed: seed)
    var question = draw.question(after: nil)
    for _ in 0..<round {
      question = draw.question(after: question)
    }
    return question
  }
}

struct GateDraw {
  var state: UInt64

  init(seed: UInt64) {
    state = seed
  }

  mutating func next() -> UInt64 {
    state &+= 0x9E37_79B9_7F4A_7C15
    var mixed = state
    mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
    mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
    return mixed ^ (mixed >> 31)
  }

  mutating func factor() -> Int {
    let span = UInt64(GateQuestion.factors.count)
    return GateQuestion.factors.lowerBound + Int(next() % span)
  }

  mutating func question(after previous: GateQuestion?) -> GateQuestion {
    while true {
      let question = GateQuestion(left: factor(), right: factor())
      if question != previous { return question }
    }
  }
}

public struct GateSeed: Sendable {
  public var draw: @Sendable () -> UInt64

  public init(draw: @escaping @Sendable () -> UInt64) {
    self.draw = draw
  }
}

extension GateSeed: DependencyKey {
  public static let liveValue = GateSeed { .random(in: .min ... .max) }
  public static let testValue = GateSeed { 1 }
  public static let previewValue = GateSeed { 1 }
}
