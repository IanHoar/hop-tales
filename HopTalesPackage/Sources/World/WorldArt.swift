import CoreGraphics
import Foundation
import UIKit

public struct WorldArt: Hashable, Sendable {
  public enum Layer: String, CaseIterable, Sendable {
    case sky
    case far
    case mid
    case near

    public var resolution: CGFloat {
      switch self {
      case .sky: 0.5
      case .far: 1
      case .mid: 1.5
      case .near: 2
      }
    }
  }

  public enum Tone: String, CaseIterable, Sendable {
    case day
    case gold
    case dusk

    public init(stage: WorldStage) {
      switch stage {
      case .meadow: self = .day
      case .castle: self = .gold
      case .dragon: self = .dusk
      }
    }
  }

  public let layer: Layer
  public let tone: Tone

  public init(_ layer: Layer, _ tone: Tone) {
    self.layer = layer
    self.tone = tone
  }

  public static var allCases: [WorldArt] {
    Layer.allCases.flatMap { layer in Tone.allCases.map { WorldArt(layer, $0) } }
  }

  public var resource: String { "\(layer.rawValue)-\(tone.rawValue)" }

  public func image(width: CGFloat) -> UIImage? {
    guard let url = Bundle.module.url(forResource: resource, withExtension: "pdf"),
      let document = CGPDFDocument(url as CFURL),
      let page = document.page(at: 1)
    else { return nil }

    let box = page.getBoxRect(.mediaBox)
    guard box.width > 0 else { return nil }
    let scale = width / box.width
    let size = CGSize(width: width, height: box.height * scale)

    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    format.opaque = layer == .sky
    return UIGraphicsImageRenderer(size: size, format: format).image { context in
      let cgContext = context.cgContext
      cgContext.translateBy(x: 0, y: size.height)
      cgContext.scaleBy(x: scale, y: -scale)
      cgContext.drawPDFPage(page)
    }
  }

  public func draw(in context: CGContext, origin: CGPoint, scale: CGFloat) {
    guard let url = Bundle.module.url(forResource: resource, withExtension: "pdf"),
      let document = CGPDFDocument(url as CFURL),
      let page = document.page(at: 1)
    else { return }
    let box = page.getBoxRect(.mediaBox)
    context.saveGState()
    context.translateBy(x: origin.x, y: origin.y + box.height * scale)
    context.scaleBy(x: scale, y: -scale)
    context.drawPDFPage(page)
    context.restoreGState()
  }

  public func texture() -> UIImage? {
    image(width: WorldMetrics.size.width * layer.resolution)
  }
}
