import SpriteKit

@MainActor
public protocol Companion: SKNode {
  func celebrate()
  func update(elapsed: TimeInterval, travelled: CGFloat)
}
