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

  @Test(arguments: [CGSize(width: 466, height: 678), CGSize(width: 669, height: 951)])
  func theDuoFoldedOrOpenGetsItsOwnLayout(size: CGSize) {
    #expect(Metrics.forScreen(size, regular: false) == .duo)
  }

  @Test func aRegularScreenUsesThePadLayout() {
    #expect(Metrics.forScreen(CGSize(width: 1032, height: 1376), regular: true) == .pad)
  }
}
