import SpriteKit

@MainActor
public protocol Companion: SKNode {
  func idle()
  func trot(for duration: TimeInterval)
  func celebrate()
}
