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
    #expect(scene.companion.position == CGPoint(x: 118, y: 844 - 441))
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

  @Test func pollenDriftsInTheWorldSoItScrollsWithIt() {
    let scene = WorldScene(size: CGSize(width: 402, height: 874))
    scene.didMove(to: SKView())
    #expect(scene.particles.targetNode === scene.actorLayer)
    #expect(scene.particles.particleBirthRate > 0)
  }

  @Test func aboutTenMotesAreOnScreenAtOnce() {
    let steady = AmbientParticles.onScreen
    #expect((8...12).contains(steady))
    let emitter = AmbientParticles.emitter()
    let perScreen = emitter.particleBirthRate * emitter.particleLifetime / AmbientParticles.coverage
    #expect(abs(perScreen - steady) < 0.001)
  }

  @Test func theCastleRoadHasDustAndDuskHasNone() {
    let scene = WorldScene(size: CGSize(width: 402, height: 874))
    scene.didMove(to: SKView())
    let pollen = scene.particles.particleColor
    scene.setStage(.castle, animated: false)
    #expect(scene.particles.particleColor != pollen)
    scene.setStage(.dragon, animated: false)
    #expect(scene.particles.particleBirthRate == 0)
  }

  @Test func motesAlsoWaitOffTheRightEdgeToScrollOn() {
    let scene = WorldScene(size: CGSize(width: 402, height: 874))
    scene.didMove(to: SKView())
    let visible = 402 / (874 / WorldMetrics.size.height)
    let range = scene.particles.particlePositionRange.dx
    #expect(abs(range - visible * 2) < 0.5)
    #expect(abs(scene.particles.position.x - range / 2) < 0.5)
  }

  @Test func theKnightAndDragonStandOnTheGroundAtTheirPlaces() {
    let scene = WorldScene(size: CGSize(width: 402, height: 874))
    scene.didMove(to: SKView())
    #expect(scene.knight.parent === scene.actorLayer)
    #expect(abs(scene.knight.position.y - Ground.height(at: 1262)) < 0.01)
    #expect(abs(scene.dragon.position.y - Ground.height(at: 2212)) < 0.01)
    #expect(scene.knight.position.x == 1262)
    #expect(scene.dragon.position.x == 2212)
  }

  @Test func theKnightWavesOnceAsTheFoxPasses() {
    let knight = KnightNode()
    knight.update(elapsed: 0.1, foxAt: 600)
    #expect(!knight.hasWaved)
    knight.update(elapsed: 0.1, foxAt: 1200)
    #expect(knight.hasWaved)
    #expect(knight.body.texture === knight.waving)
    knight.update(elapsed: KnightNode.waveTime, foxAt: 1260)
    #expect(knight.body.texture === knight.idle)
  }

  @Test func theDragonRoarsOnTheLastWordAndSettles() {
    let dragon = DragonNode()
    dragon.roar()
    dragon.update(elapsed: DragonNode.roarTime / 2)
    #expect(dragon.isRoaring)
    #expect(abs(dragon.body.yScale) > DragonNode.scale)
    dragon.update(elapsed: DragonNode.roarTime)
    #expect(!dragon.isRoaring)
    #expect(abs(dragon.body.yScale - DragonNode.scale) < 0.0001)
  }

  @Test func theDragonPlaysEveryFrameOfItsIdle() {
    let dragon = DragonNode()
    #expect(dragon.frames.count == DragonSheet.columns * DragonSheet.rows)
    var seen = Set<Int>()
    for _ in 0..<dragon.frames.count {
      dragon.update(elapsed: 1 / DragonNode.framesPerSecond)
      seen.insert(dragon.frameIndex)
      #expect(dragon.body.texture === dragon.frames[dragon.frameIndex])
    }
    #expect(seen.count == dragon.frames.count)
  }

  @Test func theDragonFacesTheFox() {
    #expect(DragonNode().body.xScale < 0)
  }

  @Test func duskGradesTheCastWithoutAFilter() {
    let scene = WorldScene(size: CGSize(width: 402, height: 874))
    scene.didMove(to: SKView())
    scene.setStage(.dragon, animated: false)
    #expect(abs(scene.dragon.body.colorBlendFactor - 0.2) < 0.001)
    scene.setStage(.meadow, animated: false)
    #expect(scene.dragon.body.colorBlendFactor == 0)
  }
}
