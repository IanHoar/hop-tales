import Content
import CoreGraphics

public struct WorldStyle: Equatable, Sendable {
  public var feetAbovePath: CGFloat?
  public var chalk = false

  public static let meadow = WorldStyle()

  @MainActor
  public static func of(_ world: Friend) -> WorldStyle {
    guard MeadowLayer.near.asset(in: world) != MeadowLayer.near.asset else { return .meadow }
    switch world {
    case .crow: return WorldStyle(feetAbovePath: 70, chalk: true)
    case .cat: return WorldStyle(feetAbovePath: 70)
    default: return .meadow
    }
  }
}
