import SpriteKit
import SwiftUI

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

#Preview("Fox poses") {
  let poses: [(String, (FoxNode) -> Void)] = [
    ("Idle", { $0.update(elapsed: 0, travelled: 0) }),
    ("Trot", { fox in (0..<9).forEach { _ in fox.update(elapsed: 1.0 / 60, travelled: 3) } }),
    ("Jump", { fox in
      fox.celebrate()
      fox.update(elapsed: FoxNode.jumpTime / 2, travelled: 0)
    })
  ]
  VStack(spacing: 12) {
    ForEach(poses, id: \.0) { name, pose in
      if let image = FoxSnapshot.image(pose) {
        Image(uiImage: image).resizable().scaledToFit().frame(height: 200)
        Text(name)
      }
    }
  }
}
