import Content
import SwiftUI

public struct DressedFriend: View {
  let friend: Friend
  let outfit: [WardrobeItem]
  let height: CGFloat

  public init(_ friend: Friend, wearing outfit: [WardrobeItem], height: CGFloat) {
    self.friend = friend
    self.outfit = outfit
    self.height = height
  }

  public var body: some View {
    let sticker = MeadowArt.image(friend == .hare ? "hare-sit" : "friend-\(friend.rawValue)")
    let aspect = sticker.map { $0.size.width / max($0.size.height, 1) } ?? 0.8
    let size = CGSize(width: height * aspect, height: height)
    ZStack(alignment: .topLeading) {
      FriendSticker(friend, height: height)
      ForEach(outfit) { item in
        ForEach(Array(item.parts.enumerated()), id: \.offset) { index, part in
          WornPart(
            name: "wear-\(friend.rawValue)-\(item.id)",
            part: part,
            half: item.parts.count > 1 ? index : nil,
            sticker: size
          )
        }
      }
    }
    .frame(width: size.width, height: size.height, alignment: .topLeading)
    .accessibilityHidden(true)
  }
}

struct WornPart: View {
  let name: String
  let part: WardrobePart
  let half: Int?
  let sticker: CGSize

  var body: some View {
    if let image = MeadowArt.image(name) {
      let imageAspect = image.size.height / max(image.size.width, 1) * (half == nil ? 1 : 2)
      let width = sticker.width * part.w
      let height = width * imageAspect
      let pivot = UnitPoint(x: part.pivot.first ?? 0.5, y: part.pivot.last ?? 0.5)
      let anchor = CGPoint(x: sticker.width * part.x, y: sticker.height * part.y)
      Image(uiImage: image)
        .resizable()
        .frame(width: half == nil ? width : width * 2, height: height)
        .frame(width: width, height: height, alignment: half == 1 ? .trailing : .leading)
        .clipped()
        .rotationEffect(.degrees(part.rot), anchor: pivot)
        .position(
          x: anchor.x + (0.5 - pivot.x) * width,
          y: anchor.y + (0.5 - pivot.y) * height
        )
    }
  }
}
