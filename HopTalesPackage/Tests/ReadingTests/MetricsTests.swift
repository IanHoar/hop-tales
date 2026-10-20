import CoreGraphics
import DesignSystem
import Testing

struct MetricsTests {
  @Test(arguments: [
    CGSize(width: 375, height: 667),
    CGSize(width: 390, height: 844),
    CGSize(width: 440, height: 956)
  ])
  func phonesUseThePhoneLayout(size: CGSize) {
    #expect(Metrics.forScreen(size, regular: false) == .phone)
  }

  @Test func theFoldedDuoGetsItsOwnLayout() {
    #expect(Metrics.forScreen(CGSize(width: 466, height: 678), regular: false) == .duo)
  }

  @Test(arguments: [
    CGSize(width: 1032, height: 1376),
    CGSize(width: 951, height: 669),
    CGSize(width: 669, height: 951)
  ])
  func aRegularScreenUsesThePadLayout(size: CGSize) {
    #expect(Metrics.forScreen(size, regular: true) == .pad)
  }
}
