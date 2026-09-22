import CoreGraphics
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
}
