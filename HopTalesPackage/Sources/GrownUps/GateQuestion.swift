import Dependencies
import Foundation

public struct GateQuestion: Hashable, Sendable {
  public let left: Int
  public let right: Int

  public init(left: Int, right: Int) {
    self.left = left
    self.right = right
  }

  public var answer: Int { left * right }

  public var digits: Int { String(answer).count }

  public var prompt: String {
    "What is \(Self.spelled(left)) times \(Self.spelled(right))?"
  }

  static func spelled(_ number: Int) -> String {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "en")
    formatter.numberStyle = .spellOut
    return formatter.string(from: number as NSNumber) ?? String(number)
  }
}

public struct GateQuestions: Sendable {
  public var next: @Sendable () -> GateQuestion

  public init(next: @escaping @Sendable () -> GateQuestion) {
    self.next = next
  }
}

extension GateQuestions: DependencyKey {
  public static let factors = 3...9

  public static let liveValue = GateQuestions {
    GateQuestion(left: .random(in: factors), right: .random(in: factors))
  }

  public static let testValue = GateQuestions { GateQuestion(left: 7, right: 6) }
}
