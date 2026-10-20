import CoreGraphics
import Testing

@testable import World

struct IntroLayoutTests {
  let phoneArt = CGSize(width: 440, height: 956)
  let padArt = CGSize(width: 1376, height: 1032)

  @Test(arguments: [CGSize(width: 393, height: 852), CGSize(width: 440, height: 956)])
  func aPhoneShowsTheLaunchArtAtItsOwnSize(screen: CGSize) {
    #expect(IntroLayout.launchSize(phoneArt, filling: screen) == phoneArt)
  }

  @Test func theFoldedDuoWidensTheLaunchArtToItsEdge() {
    let size = IntroLayout.launchSize(phoneArt, filling: CGSize(width: 466, height: 678))
    #expect(size.width == 466)
    #expect(abs(size.width / size.height - phoneArt.width / phoneArt.height) < 0.0001)
  }

  @Test(arguments: [CGSize(width: 1376, height: 1032), CGSize(width: 1032, height: 1376)])
  func anIPadShowsItsLaunchArtAtItsOwnSize(screen: CGSize) {
    #expect(IntroLayout.launchSize(padArt, filling: screen) == padArt)
  }
}
