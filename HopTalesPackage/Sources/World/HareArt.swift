import Content
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

public struct AppMark: View {
  let size: CGFloat

  public init(size: CGFloat = 40) {
    self.size = size
  }

  public var body: some View {
    Group {
      if let image = MeadowArt.image("app-mark") {
        Image(uiImage: image).resizable()
      } else {
        Color.clear
      }
    }
    .frame(width: size, height: size)
    .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
    .shadow(color: .black.opacity(0.22), radius: 3.5, y: 3)
    .accessibilityHidden(true)
  }
}

public struct FriendSticker: View {
  let friend: Friend
  let height: CGFloat
  var isSilhouette = false

  public init(_ friend: Friend, height: CGFloat, isSilhouette: Bool = false) {
    self.friend = friend
    self.height = height
    self.isSilhouette = isSilhouette
  }

  public var body: some View {
    if let image = MeadowArt.image(friend == .hare ? "hare-sit" : "friend-\(friend.rawValue)") {
      let width = height * image.size.width / max(image.size.height, 1)
      Group {
        if isSilhouette {
          Image(uiImage: image)
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(.secondary)
        } else {
          Image(uiImage: image).resizable()
        }
      }
      .frame(width: width, height: height)
      .accessibilityHidden(true)
    }
  }
}

public struct Sticker: View {
  let name: String
  let height: CGFloat

  public init(_ name: String, height: CGFloat) {
    self.name = name
    self.height = height
  }

  public static func postcard(_ friend: Friend) -> String {
    friend == .hare ? "near-day" : "postcard-\(friend.rawValue)"
  }

  public var body: some View {
    if let image = MeadowArt.image(name) {
      Image(uiImage: image)
        .resizable()
        .frame(width: height * image.size.width / max(image.size.height, 1), height: height)
        .accessibilityHidden(true)
    }
  }
}
