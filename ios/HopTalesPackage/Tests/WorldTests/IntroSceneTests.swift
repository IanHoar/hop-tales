import CoreGraphics
import SpriteKit
import Testing

@testable import World

@MainActor
struct IntroSceneTests {
  @Test(arguments: [CGSize(width: 820, height: 1180), CGSize(width: 1376, height: 1032)])
  func theNightLandIsShadedTileByTileOnAnIPad(size: CGSize) {
    let scene = IntroScene(size: size)
    let tiles = scene.layers.flatMap(\.tiles)
    #expect(!tiles.isEmpty)
    #expect(tiles.allSatisfy { $0.shader != nil })
    #expect(!(scene.land is SKEffectNode))
  }
}
