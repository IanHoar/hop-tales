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

#Preview("Cast") {
  let roaring = DragonNode()
  roaring.roar()
  roaring.update(elapsed: 0.3)
  let waving = KnightNode()
  waving.update(elapsed: 0.1, foxAt: KnightNode.home)
  let size = CGSize(width: 320, height: 240)
  let cast: [(String, UIImage?)] = [
    ("Sir Pennant", CastSnapshot.image(of: KnightNode(), size: size, scale: 1.4)),
    ("Waving", CastSnapshot.image(of: waving, size: size, scale: 1.4)),
    ("Ember", CastSnapshot.image(of: DragonNode(), size: size, scale: 1)),
    ("Roar", CastSnapshot.image(of: roaring, size: size, scale: 1))
  ]
  return ScrollView {
    VStack(spacing: 8) {
      ForEach(cast, id: \.0) { name, image in
        if let image {
          Image(uiImage: image).resizable().scaledToFit().frame(height: 170)
          Text(name)
        }
      }
    }
  }
}
