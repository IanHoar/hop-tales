import SpriteKit
import SwiftUI

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

#Preview("Fox") {
  @Previewable @State var stage = FoxStage(size: CGSize(width: 400, height: 300))
  VStack {
    SpriteView(scene: stage)
      .frame(width: 400, height: 300)
    HStack {
      Button("Jump") { stage.fox.celebrate() }
      Button("Trot") { stage.trotting.toggle() }
    }
    .buttonStyle(.borderedProminent)
  }
}
