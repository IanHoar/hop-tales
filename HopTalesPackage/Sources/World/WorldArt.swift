import CoreGraphics
import Foundation
import UIKit

public enum WorldArt: String, CaseIterable, Sendable {
  case layerFar = "layer-far"
  case layerMid = "layer-mid"
  case layerNear = "layer-near"
  case spriteDragon = "sprite-dragon"

  public static func sky(_ stage: WorldStage) -> UIImage? {
    UIImage(named: stage.skyAsset, in: .module, compatibleWith: nil)
  }

  public func image(width: CGFloat) -> UIImage? {
    guard let url = Bundle.module.url(forResource: rawValue, withExtension: "pdf"),
      let document = CGPDFDocument(url as CFURL),
      let page = document.page(at: 1)
    else { return nil }

    let box = page.getBoxRect(.mediaBox)
    guard box.width > 0 else { return nil }
    let scale = width / box.width
    let size = CGSize(width: width, height: box.height * scale)

    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    format.opaque = false
    return UIGraphicsImageRenderer(size: size, format: format).image { context in
      let cgContext = context.cgContext
      cgContext.translateBy(x: 0, y: size.height)
      cgContext.scaleBy(x: scale, y: -scale)
      cgContext.drawPDFPage(page)
    }
  }
}
