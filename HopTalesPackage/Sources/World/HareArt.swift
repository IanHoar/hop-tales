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
  public private(set) var asset: String
  public let cell: CGSize
  public let anchor: UnitPoint
  public let scale: CGFloat
  public let frameCount: Int

  init(_ asset: String, cell: CGSize, feet: CGPoint, scale: CGFloat = 1, frames: Int) {
    self.asset = asset
    self.cell = cell
    anchor = UnitPoint(x: feet.x / cell.width, y: feet.y / cell.height)
    self.scale = scale
    frameCount = frames
  }

  func named(_ asset: String) -> SpriteSheet {
    var sheet = self
    sheet.asset = asset
    return sheet
  }

  static func idle(
    _ asset: String, cell: CGSize, feet: CGPoint, size: CGFloat = 1
  ) -> SpriteSheet {
    SpriteSheet(asset, cell: cell, feet: feet, scale: size, frames: HareSheet.idle.frameCount)
  }

  static func hop(
    _ asset: String, cell: CGSize, feet: CGPoint, standing: CGFloat, size: CGFloat = 1
  ) -> SpriteSheet {
    SpriteSheet(
      asset, cell: cell, feet: feet, scale: HareSheet.restHeight / standing * size,
      frames: HareSheet.hop.frameCount
    )
  }

  private typealias Pair = (idle: SpriteSheet, hop: SpriteSheet)

  private static let hare: Pair = (
    .idle("hare-idle-frames", cell: CGSize(width: 260, height: 373), feet: CGPoint(x: 142, y: 361)),
    .hop(
      "hare-hop", cell: CGSize(width: 363, height: 346), feet: CGPoint(x: 194, y: 334),
      standing: 322
    )
  )

  private static let sheets: [Friend: Pair] = [
    .bunny: (
      .idle(
        "bunny-idle-frames", cell: CGSize(width: 322, height: 369), feet: CGPoint(x: 158, y: 357)
      ),
      .hop(
        "bunny-hop", cell: CGSize(width: 370, height: 346), feet: CGPoint(x: 175, y: 335),
        standing: 323
      )
    ),
    .frog: (
      .idle(
        "frog-idle-frames", cell: CGSize(width: 447, height: 400), feet: CGPoint(x: 222, y: 384)
      ),
      .hop(
        "frog-hop", cell: CGSize(width: 396, height: 346), feet: CGPoint(x: 206, y: 335),
        standing: 242
      )
    ),
    .crab: (
      .idle(
        "crab-idle-frames", cell: CGSize(width: 621, height: 517), feet: CGPoint(x: 305, y: 496),
        size: 0.75
      ),
      .hop(
        "crab-hop", cell: CGSize(width: 440, height: 346), feet: CGPoint(x: 211, y: 333),
        standing: 286, size: 0.75
      )
    ),
    .crow: (
      .idle(
        "crow-idle-frames", cell: CGSize(width: 370, height: 369), feet: CGPoint(x: 227, y: 357)
      ),
      .hop(
        "crow-hop", cell: CGSize(width: 338, height: 346), feet: CGPoint(x: 166, y: 336),
        standing: 259
      )
    ),
    .cat: (
      .idle(
        "cat-idle-frames", cell: CGSize(width: 291, height: 366), feet: CGPoint(x: 150, y: 355)
      ),
      .hop(
        "cat-hop", cell: CGSize(width: 422, height: 346), feet: CGPoint(x: 182, y: 335),
        standing: 305
      )
    ),
    .grasshopper: (
      .idle(
        "grasshopper-idle-frames", cell: CGSize(width: 562, height: 380),
        feet: CGPoint(x: 245, y: 363)
      ),
      .hop(
        "grasshopper-hop", cell: CGSize(width: 321, height: 346), feet: CGPoint(x: 137, y: 336),
        standing: 170
      )
    )
  ]

  public static func of(_ sheet: HareSheet, for friend: Friend) -> SpriteSheet {
    let pair = sheets[friend] ?? hare
    return sheet == .idle ? pair.idle : pair.hop
  }
}

public struct HareFrame: Equatable, Sendable {
  public var sheet: HareSheet
  public var index: Int
  public var friend: Friend

  public var look: String?

  public init(_ sheet: HareSheet, _ index: Int, friend: Friend = .hare, look: String? = nil) {
    self.sheet = sheet
    self.index = index
    self.friend = friend
    self.look = look
  }

  public static let rest = HareFrame(.idle, 0)

  @MainActor
  public var art: SpriteSheet {
    let base = SpriteSheet.of(sheet, for: friend)
    guard let look else { return base }
    let dressed = "look-\(friend.rawValue)-\(look)-\(sheet == .idle ? "idle" : "hop")"
    return MeadowArt.image(dressed) == nil ? base : base.named(dressed)
  }
}

@MainActor
public enum HareArt {
  private static var frames: [String: UIImage] = [:]

  public static func image(_ frame: HareFrame) -> UIImage? {
    let asset = frame.art.asset
    let key = "\(asset)-\(min(frame.index, frame.art.frameCount - 1))"
    if let cached = frames[key] { return cached }
    guard
      let sheet = MeadowArt.image(asset),
      let cgImage = sheet.cgImage
    else { return nil }
    let art = frame.art
    let width = CGFloat(cgImage.width) / CGFloat(art.frameCount)
    let rect = CGRect(
      x: CGFloat(min(frame.index, art.frameCount - 1)) * width,
      y: 0,
      width: width,
      height: CGFloat(cgImage.height)
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
