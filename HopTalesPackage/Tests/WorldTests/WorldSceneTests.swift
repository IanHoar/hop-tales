import CoreGraphics
import SpriteKit
import Testing

@testable import World

@MainActor
struct WorldSceneTests {
  @Test func eachLayerMovesAtItsOwnSpeed() {
    let offsets = LayerOffsets(progress: 1000)
    #expect(offsets.far == -300)
    #expect(offsets.mid == -600)
    #expect(offsets.near == -1000)
  }

  @Test func theSceneMovesItsLayersToTheOffsets() {
    let scene = WorldScene(size: CGSize(width: 402, height: 874))
    scene.setProgress(1000, animated: false)
    #expect(scene.farLayer.position.x == -300)
    #expect(scene.midLayer.position.x == -600)
    #expect(scene.nearLayer.position.x == -1000)
    #expect(scene.actorLayer.position.x == -1000)
    #expect(scene.skyNode.position.x == 0)
  }

  @Test func theStagesChangeAtTheSpecBoundaries() {
    #expect(WorldStage(progress: 0) == .meadow)
    #expect(WorldStage(progress: 60) == .meadow)
    #expect(WorldStage(progress: 649) == .meadow)
    #expect(WorldStage(progress: 650) == .castle)
    #expect(WorldStage(progress: 1000) == .castle)
    #expect(WorldStage(progress: 1400) == .dragon)
    #expect(WorldStage(progress: 1950) == .dragon)
  }

  @Test func theEndOfTheStoryStillFillsAPhoneWithNearLayer() {
    let remaining = WorldMetrics.size.width - WorldMetrics.traverse
    #expect(remaining >= 390)
  }

  @Test func settingProgressMovesTheSceneToThatStage() {
    let scene = WorldScene(size: CGSize(width: 402, height: 874))
    scene.setProgress(1500, animated: false)
    #expect(scene.stage == .dragon)
  }

  @Test func theScrollEasesOutExponentially() {
    #expect(WorldScene.easeOutExpo(0) == 0)
    #expect(WorldScene.easeOutExpo(1) == 1)
    #expect(WorldScene.easeOutExpo(0.3) > 0.85)
  }

  @Test func theFoxStandsOnTheGroundAtItsHomeSpot() {
    let scene = WorldScene(size: CGSize(width: 402, height: 874))
    scene.didMove(to: SKView())
    #expect(scene.companion is FoxNode)
    #expect(scene.companion.position == CGPoint(x: 150, y: 844 - 436))
    #expect(scene.companion.parent === scene.companionLayer)
  }

  @Test func theFoxStaysOnScreenWhileTheWorldScrolls() {
    let scene = WorldScene(size: CGSize(width: 402, height: 874))
    scene.didMove(to: SKView())
    scene.setProgress(1000, animated: false)
    #expect(scene.companionLayer.position.x == 0)
    #expect(scene.nearLayer.position.x == -1000)
  }

  @Test func aNewCompanionReplacesTheFox() {
    let scene = WorldScene(size: CGSize(width: 402, height: 874))
    scene.didMove(to: SKView())
    let fox = scene.companion
    scene.companion = FoxNode()
    #expect(fox.parent == nil)
    #expect(scene.companionLayer.children.count == 1)
  }

  @Test func readingAWordMakesTheFoxJump() {
    let fox = FoxNode()
    fox.celebrate()
    fox.update(elapsed: FoxNode.jumpTime / 2, travelled: 0)
    #expect(abs(fox.figure.position.y - FoxNode.jumpHeight) < 0.01)
    fox.update(elapsed: FoxNode.jumpTime + FoxNode.landTime, travelled: 0)
    #expect(fox.figure.position.y == 0)
    #expect(fox.figure.yScale == 1)
  }

  @Test func theLegsOnlyMoveWhileTheGroundDoes() {
    let fox = FoxNode()
    for _ in 0..<10 {
      fox.update(elapsed: 1.0 / 60, travelled: 4)
    }
    #expect(fox.backLegs.contains { abs($0.zRotation) > 0.05 })
    for _ in 0..<60 {
      fox.update(elapsed: 1.0 / 60, travelled: 0)
    }
    #expect((fox.backLegs + fox.frontLegs).allSatisfy { abs($0.zRotation) < 0.01 })
  }

  @Test func diagonalLegsSwingTogether() {
    let fox = FoxNode()
    for _ in 0..<5 {
      fox.update(elapsed: 1.0 / 60, travelled: 3)
    }
    #expect(abs(fox.backLegs[0].zRotation - fox.frontLegs[1].zRotation) < 0.0001)
    #expect(abs(fox.backLegs[1].zRotation - fox.frontLegs[0].zRotation) < 0.0001)
    #expect(abs(fox.backLegs[0].zRotation + fox.backLegs[1].zRotation) < 0.0001)
  }
}
