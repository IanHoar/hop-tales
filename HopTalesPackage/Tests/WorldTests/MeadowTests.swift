import Content
import CoreGraphics
import SpriteKit
import Testing

@testable import World

@MainActor
struct MeadowTests {
  nonisolated static let phone = MeadowLayout(size: CGSize(width: 390, height: 844))
  nonisolated static let pad = MeadowLayout(size: CGSize(width: 820, height: 1180))

  @Test func thePhoneLandScaleIsTheBaseScale() {
    #expect(Self.phone.scale == MeadowLayout.baseScale)
    #expect(Self.phone.k == 1)
  }

  @Test func theIPadLandGrowsWithTheShortSide() {
    #expect(abs(Self.pad.scale - 0.42 * 820 / 390 * 0.62) < 0.0001)
  }

  @Test(arguments: [phone, pad])
  func starsNeverStackOrCrossTheMoon(layout: MeadowLayout) {
    let stars = MeadowStars.field(for: layout)
    #expect(stars.count >= 4)
    for (index, star) in stars.enumerated() {
      for other in stars[(index + 1)...] {
        let gap = hypot(star.centre.x - other.centre.x, star.centre.y - other.centre.y)
        #expect(gap > (star.width + other.width) / 2)
      }
      let moon = hypot(star.centre.x - layout.moonCentre.x, star.centre.y - layout.moonCentre.y)
      #expect(moon > layout.moonSize.width / 2 + star.width / 2)
    }
  }

  @Test func theLayersFollowTheHandoffAnchors() {
    let layout = Self.phone
    #expect(abs(layout.top(of: .far) - (844 - 986 * 0.42)) < 0.001)
    #expect(abs(layout.top(of: .mid) - (844 - 848 * 0.42)) < 0.001)
    #expect(abs(layout.top(of: .near) - (844 - 705 * 0.42)) < 0.001)
    #expect(abs(layout.pathY - (layout.top(of: .near) + 430 * 0.42)) < 0.001)
  }

  @Test(arguments: MeadowLayer.allCases)
  func eachLayerLoopsWithinOneTile(layer: MeadowLayer) {
    let width = Self.phone.tileSize(of: layer).width
    for progress in stride(from: 0.0, through: 20_000, by: 733) {
      let offset = Self.phone.offset(of: layer, progress: progress)
      #expect(offset <= 0)
      #expect(offset > -width)
    }
  }

  @Test func nearerLayersMoveFaster() {
    let progress = 300.0
    let far = -Self.phone.offset(of: .far, progress: progress)
    let mid = -Self.phone.offset(of: .mid, progress: progress)
    let near = -Self.phone.offset(of: .near, progress: progress)
    #expect(far < mid)
    #expect(mid < near)
    #expect(abs(near - 300) < 0.001)
  }

  @Test func theLoopsAreDifferentLengthsSoTheyNeverLineUpTheSameWay() {
    let widths = Set(MeadowLayer.allCases.map { Self.phone.tileSize(of: $0).width })
    #expect(widths.count == 3)
  }

  @Test func enoughTilesAlwaysCoverTheScreen() {
    for layer in MeadowLayer.allCases {
      let covered = CGFloat(Self.pad.tileCount(of: layer) - 1) * Self.pad.tileSize(of: layer).width
      #expect(covered >= Self.pad.size.width)
    }
  }

  @Test func propsAreTheSameEveryTimeASegmentComesBack() {
    for segment in -3...12 {
      let first = MeadowProps.placements(inSegment: segment)
      #expect(first == MeadowProps.placements(inSegment: segment))
      for placement in MeadowProps.placements(inSegment: segment) {
        #expect((0...MeadowProps.segmentWidth).contains(placement.x))
      }
    }
  }

  @Test func onlyNightAndDuskShowStars() {
    #expect(Sky.day.style.stars == 0)
    #expect(Sky.golden.style.stars == 0)
    #expect(Sky.night.style.stars == 1)
    #expect(Sky.dusk.style.stars > 0)
  }

  @Test func aStormDimsTheLand() {
    let clear = Mood(sky: .day, weather: .clear).tint(for: .near)
    let storm = Mood(sky: .day, weather: .storm).tint(for: .near)
    var clearGreen: CGFloat = 0
    var stormGreen: CGFloat = 0
    clear.getRed(nil, green: &clearGreen, blue: nil, alpha: nil)
    storm.getRed(nil, green: &stormGreen, blue: nil, alpha: nil)
    #expect(abs(stormGreen - clearGreen * 0.74) < 0.001)
  }

  @Test func theSceneFollowsTheMoodAndProgress() {
    let scene = MeadowScene(size: CGSize(width: 390, height: 844))
    scene.setMood(Mood(sky: .night), animated: false)
    #expect(scene.sky.starAlpha == 1)
    scene.setMood(Mood(sky: .day, weather: .rain), animated: false)
    #expect(scene.sky.starAlpha == 0)
    #expect(scene.sky.rainIsFalling)
    scene.setProgress(420, animated: false)
    #expect(scene.shown == 420)
    let near = scene.layers.first { $0.layer == .near }
    #expect(abs((near?.tiles.first?.position.x ?? 0) + 420) < 0.001)
  }

  @Test func aProgressChangeEasesTowardsTheTarget() {
    let scene = MeadowScene(size: CGSize(width: 390, height: 844))
    scene.setProgress(1000)
    scene.update(1)
    scene.update(1.05)
    #expect(scene.shown > 0)
    #expect(scene.shown < 1000)
  }
}
