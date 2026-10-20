import CoreText
import Foundation

public enum FontRegistry {
  public static let faces = [
    "YoungSerif-Regular", "Fraunces-Bold", "Fredoka-Medium", "Fredoka-SemiBold", "Fredoka-Bold"
  ]

  static let registered: Bool = {
    guard let urls = Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: nil)
    else { return false }
    CTFontManagerRegisterFontURLs(urls as CFArray, .process, true, nil)
    return true
  }()

  @discardableResult
  public static func register() -> Bool { registered }
}
