import DesignSystem
import Testing
import UIKit

struct FontTests {
  @Test(arguments: FontRegistry.faces)
  func everyFaceIsBundledAndRegistered(face: String) {
    #expect(FontRegistry.register())
    #expect(UIFont(name: face, size: 20) != nil)
  }

  @Test func wordsAreMeasuredInYoungSerif() {
    #expect(Typography.wordUIFont(20).fontName == "YoungSerif-Regular")
  }
}
