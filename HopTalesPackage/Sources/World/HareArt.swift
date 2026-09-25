import Content
import SwiftUI
import UIKit

public enum HareSheet: Sendable {
  case idle
  case hop

  public var frameCount: Int {
    switch self {
    case .idle: 10
    case .hop: 8
    }
  }

  public static let restHeight: CGFloat = 345
}

public struct SpriteSheet: Equatable, Sendable {
  public let asset: String
  public let cell: CGSize
  public let anchor: UnitPoint
  public let scale: CGFloat

  public static func of(_ sheet: HareSheet, for friend: Friend) -> SpriteSheet {
    switch (sheet, SpriteSheet.hasOwnSheets(friend) ? friend : .hare) {
    case (.idle, .bunny):
      SpriteSheet(
        asset: "bunny-idle-frames",
        cell: CGSize(width: 322, height: 369),
        anchor: UnitPoint(x: 158 / 322, y: 357 / 369),
        scale: 1
      )
    case (.hop, .bunny):
      SpriteSheet(
        asset: "bunny-hop",
        cell: CGSize(width: 370, height: 346),
        anchor: UnitPoint(x: 175 / 370, y: 335 / 346),
        scale: 344 / 323
      )
    case (.idle, _):
      SpriteSheet(
        asset: "hare-idle-frames",
        cell: CGSize(width: 260, height: 373),
        anchor: UnitPoint(x: 142 / 260, y: 361 / 373),
        scale: 1
      )
    case (.hop, _):
      SpriteSheet(
        asset: "hare-hop",
        cell: CGSize(width: 363, height: 346),
        anchor: UnitPoint(x: 194 / 363, y: 334 / 346),
        scale: 345 / 322
      )
    }
  }

  public static func hasOwnSheets(_ friend: Friend) -> Bool {
    [.hare, .bunny].contains(friend)
  }
}

public struct HareFrame: Equatable, Sendable {
  public var sheet: HareSheet
  public var index: Int
  public var friend: Friend

  public init(_ sheet: HareSheet, _ index: Int, friend: Friend = .hare) {
    self.sheet = sheet
    self.index = index
    self.friend = friend
  }

  public static let rest = HareFrame(.idle, 0)

  public var art: SpriteSheet { .of(sheet, for: friend) }
}

@MainActor
public enum HareArt {
  private static var frames: [String: UIImage] = [:]

  public static func image(_ frame: HareFrame) -> UIImage? {
    let asset = frame.art.asset
    let key = "\(asset)-\(frame.index)"
    if let cached = frames[key] { return cached }
    guard
      let sheet = MeadowArt.image(asset),
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
    let art = frame.art
    let pointsPerPixel = height / HareSheet.restHeight * art.scale
    let size = CGSize(
      width: art.cell.width * pointsPerPixel, height: art.cell.height * pointsPerPixel
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
      x: size.width * (0.5 - art.anchor.x),
      y: size.height * (0.5 - art.anchor.y)
    )
    .frame(width: 0, height: 0)
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
