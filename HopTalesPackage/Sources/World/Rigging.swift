import CoreGraphics
import Foundation
import SpriteKit
import UIKit

struct Rigging: Decodable {
  struct Point: Decodable {
    let x: CGFloat
    let y: CGFloat
  }

  struct Canvas: Decodable {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
  }

  let canvas: Canvas
  let pivots: [String: Point]

  static let fox = load("fox-pivots")
  static let dragon = load("dragon-pivots")
  static let knight = load("knight-pivots")

  static func load(_ name: String) -> Rigging {
    guard let url = Bundle.module.url(forResource: name, withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let rigging = try? JSONDecoder().decode(Rigging.self, from: data)
    else {
      return Rigging(canvas: Canvas(x: 0, y: 0, width: 1, height: 1), pivots: [:])
    }
    return rigging
  }

  func texture(_ name: String) -> SKTexture? {
    UIImage(named: name, in: .module, compatibleWith: nil).map(SKTexture.init(image:))
  }

  func sprite(_ name: String) -> SKSpriteNode {
    let pivot = pivots[name] ?? Point(x: 0, y: 0)
    let sprite = SKSpriteNode(
      texture: texture(name),
      size: CGSize(width: canvas.width, height: canvas.height)
    )
    sprite.name = name
    sprite.anchorPoint = CGPoint(
      x: (pivot.x - canvas.x) / canvas.width,
      y: (canvas.y + canvas.height - pivot.y) / canvas.height
    )
    sprite.position = CGPoint(x: pivot.x, y: -pivot.y)
    return sprite
  }
}
