import Content
import CoreGraphics

public struct WorldStyle: Equatable, Sendable {
  public var feetAbovePath: CGFloat?
  public var chalk = false
  public var ground: UInt32 = 0xB7BF7B

  public static let meadow = WorldStyle()

  @MainActor
  public static func of(_ world: Friend) -> WorldStyle {
    guard MeadowLayer.hasOwnLand(world) else { return .meadow }
    switch world {
    case .bunny: return WorldStyle(ground: 0x919670)
    case .frog: return WorldStyle(ground: 0xB6AE66)
    case .crab: return WorldStyle(ground: 0xD4AF6F)
    case .grasshopper: return WorldStyle(ground: 0xC0B66D)
    case .crow: return WorldStyle(feetAbovePath: 70, chalk: true)
    case .cat: return WorldStyle(feetAbovePath: 70)
    case .hare: return .meadow
    }
  }
}
