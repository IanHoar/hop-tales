import CoreGraphics
import DesignSystem
import Testing

struct FoldTests {
  let screen = CGSize(width: 669, height: 951)

  @Test func aFoldAcrossTheScreenLeavesTheHalfBelowIt() {
    let fold = Fold(CGRect(x: 0, y: 455, width: 669, height: 40))
    #expect(fold.runsAcross)
    #expect(fold.room(in: screen) == CGRect(x: 0, y: 495, width: 669, height: 456))
  }

  @Test func aFoldDownTheScreenLeavesTheHalfAfterIt() {
    let fold = Fold(CGRect(x: 314, y: 0, width: 40, height: 951))
    #expect(!fold.runsAcross)
    #expect(fold.room(in: screen) == CGRect(x: 354, y: 0, width: 315, height: 951))
  }

  @Test func theStageIsTheSideAwayFromTheSheet() {
    #expect(
      Fold(CGRect(x: 0, y: 455, width: 669, height: 40)).stage(in: screen)
        == CGRect(x: 0, y: 0, width: 669, height: 455)
    )
    #expect(
      Fold(CGRect(x: 314, y: 0, width: 40, height: 951)).stage(in: screen)
        == CGRect(x: 0, y: 0, width: 314, height: 951)
    )
  }
}
