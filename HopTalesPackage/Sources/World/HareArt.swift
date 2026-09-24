import SwiftUI
import UIKit

public enum HareSheet: Sendable {
  case idle
  case hop

  var asset: String {
    switch self {
    case .idle: "hare-idle-frames"
    case .hop: "hare-hop"
    }
  }

  public var frameCount: Int {
    switch self {
    case .idle: 10
    case .hop: 8
    }
  }

  public var cell: CGSize {
    switch self {
    case .idle: CGSize(width: 260, height: 373)
    case .hop: CGSize(width: 363, height: 346)
    }
  }

  public var anchor: UnitPoint {
    switch self {
    case .idle: UnitPoint(x: 142 / 260, y: 361 / 373)
    case .hop: UnitPoint(x: 194 / 363, y: 334 / 346)
    }
  }

  public var scale: CGFloat {
    switch self {
    case .idle: 1
    case .hop: 345 / 322
    }
  }

  public static let restHeight: CGFloat = 345
}

public struct HareFrame: Equatable, Sendable {
  public var sheet: HareSheet
  public var index: Int

  public init(_ sheet: HareSheet, _ index: Int) {
    self.sheet = sheet
    self.index = index
  }

  public static let rest = HareFrame(.idle, 0)
}

@MainActor
public enum HareArt {
  private static var frames: [String: UIImage] = [:]

  public static func image(_ frame: HareFrame) -> UIImage? {
    let key = "\(frame.sheet.asset)-\(frame.index)"
    if let cached = frames[key] { return cached }
    guard
      let sheet = MeadowArt.image(frame.sheet.asset),
      let cgImage = sheet.cgImage
    else { return nil }
    let width = CGFloat(cgImage.width) / CGFloat(frame.sheet.frameCount)
    let rect = CGRect(
      x: CGFloat(frame.index) * width, y: 0, width: width, height: CGFloat(cgImage.height)
    )
    guard let cell = cgImage.cropping(to: rect) else { return nil }
    let image = UIImage(cgImage: cell, scale: sheet.scale, orientation: .up)
    frames[key] = image
    return image
  }
}

public struct HareSprite: View {
  let frame: HareFrame
  let height: CGFloat

  public init(_ frame: HareFrame, height: CGFloat) {
    self.frame = frame
    self.height = height
  }

  public var body: some View {
    let sheet = frame.sheet
    let pointsPerPixel = height / HareSheet.restHeight * sheet.scale
    let size = CGSize(
      width: sheet.cell.width * pointsPerPixel, height: sheet.cell.height * pointsPerPixel
    )
    Group {
      if let image = HareArt.image(frame) {
        Image(uiImage: image).resizable()
      } else {
        Color.clear
      }
    }
    .frame(width: size.width, height: size.height)
    .offset(
      x: size.width * (0.5 - sheet.anchor.x),
      y: size.height * (0.5 - sheet.anchor.y)
    )
    .frame(width: 0, height: 0)
    .accessibilityHidden(true)
  }
}
