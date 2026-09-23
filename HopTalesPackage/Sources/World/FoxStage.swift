import SpriteKit
import UIKit

@MainActor
final class FoxStage: SKScene {
  let fox = FoxNode()
  var trotting = false

  override init(size: CGSize) {
    super.init(size: size)
    backgroundColor = UIColor(red: 0.56, green: 0.8, blue: 0.42, alpha: 1)
    fox.setScale(3)
    fox.position = CGPoint(x: size.width / 2, y: size.height * 0.3)
    addChild(fox)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  private var last: TimeInterval?

  override func update(_ currentTime: TimeInterval) {
    let elapsed = last.map { currentTime - $0 } ?? 0
    last = currentTime
    fox.update(elapsed: elapsed, travelled: trotting ? CGFloat(elapsed) * 180 : 0)
  }
}

@MainActor
enum FoxSnapshot {
  static func image(scale: CGFloat = 2.5, _ pose: (FoxNode) -> Void) -> UIImage? {
    let view = SKView(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
    let scene = SKScene(size: view.bounds.size)
    scene.backgroundColor = UIColor(red: 0.56, green: 0.8, blue: 0.42, alpha: 1)
    let fox = FoxNode()
    fox.setScale(scale)
    fox.position = CGPoint(x: 160, y: 30)
    pose(fox)
    scene.addChild(fox)
    view.presentScene(scene)
    return view.texture(from: scene).map { UIImage(cgImage: $0.cgImage()) }
  }
}
