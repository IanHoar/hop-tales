import Testing
import UIKit

@testable import World

struct WorldArtTests {
  @Test(arguments: WorldArt.allCases)
  func everyLayerShipsInEveryPalette(art: WorldArt) {
    let image = art.image(width: 1170)
    #expect(image != nil)
    #expect(image?.size.width == 1170)
  }

  @Test func theWorldKeepsItsAspectRatio() {
    let image = WorldArt(.near, .day).image(width: 2340)
    #expect(image?.size.height == 844)
  }

  @Test func aLayerCanBeAskedForAnySizeWithoutARenderStep() {
    let small = WorldArt(.far, .day).image(width: 390)
    let large = WorldArt(.far, .day).image(width: 4680)
    #expect(small?.size.width == 390)
    #expect(large?.size.width == 4680)
  }

  @Test func eachStageHasItsOwnPalette() {
    #expect(WorldArt.Tone(stage: .meadow) == .day)
    #expect(WorldArt.Tone(stage: .castle) == .gold)
    #expect(WorldArt.Tone(stage: .dragon) == .dusk)
  }

  @Test func theNearLayerIsRasterisedSharpestAndTheSkySoftest() {
    #expect(WorldArt(.near, .day).texture()?.size.width == 4680)
    #expect(WorldArt(.sky, .day).texture()?.size.width == 1170)
  }
}
