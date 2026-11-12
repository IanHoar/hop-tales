import Content
import Testing

@testable import World

struct SpriteSheetTests {
  @Test func theHopIsScaledToTheRestingHeight() {
    #expect(SpriteSheet.of(.idle, for: .bunny).scale == 1)
    #expect(abs(SpriteSheet.of(.hop, for: .bunny).scale - 345 / 323) < 1e-6)
    #expect(abs(SpriteSheet.of(.hop, for: .grasshopper).scale - 345 / 166) < 1e-6)
  }

  @Test func skipStandsALittleTallerThanBob() {
    #expect(SpriteSheet.of(.idle, for: .hare).scale == 1.2)
    #expect(abs(SpriteSheet.of(.hop, for: .hare).scale - 345 / 322 * 1.2) < 1e-6)
  }

  @Test func barnacleIsDrawnAtThreeQuarters() {
    #expect(SpriteSheet.of(.idle, for: .crab).scale == 0.75)
    #expect(abs(SpriteSheet.of(.hop, for: .crab).scale - 345 / 262 * 0.75) < 1e-6)
  }
}
