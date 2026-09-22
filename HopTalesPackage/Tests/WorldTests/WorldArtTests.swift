import Testing
import UIKit

@testable import World

struct WorldArtTests {
  @Test(arguments: WorldArt.allCases)
  func everyLayerRasterisesAtTheWidthItIsAsked(art: WorldArt) {
    let image = art.image(width: 1170)
    #expect(image != nil)
    #expect(image?.size.width == 1170)
  }

  @Test func theWorldKeepsItsAspectRatio() {
    let image = WorldArt.layerNear.image(width: 2340)
    #expect(image?.size.height == 844)
  }

  @Test func aLayerCanBeAskedForAnySizeWithoutARenderStep() {
    let small = WorldArt.layerFar.image(width: 390)
    let large = WorldArt.layerFar.image(width: 4680)
    #expect(small?.size.width == 390)
    #expect(large?.size.width == 4680)
  }

  @Test(arguments: WorldStage.allCases)
  func everyStageHasASky(stage: WorldStage) {
    #expect(WorldArt.sky(stage) != nil)
  }
}
