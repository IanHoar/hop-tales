import Content
import DesignSystem
import QuartzCore
import SwiftUI

public struct IdleFriend: View {
  let friend: Friend
  let look: String?
  let height: CGFloat
  var isPaused = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.freezesMotion) private var freezesMotion

  public init(_ friend: Friend, look: String?, height: CGFloat, isPaused: Bool = false) {
    self.friend = friend
    self.look = look
    self.height = height
    self.isPaused = isPaused
  }

  public var body: some View {
    let still = reduceMotion || freezesMotion
    let rest = HareFrame(.idle, HareFrame.rest.index, friend: friend, look: look)
    let art = rest.art
    let width = height / HareSheet.restHeight * art.scale * art.cell.width
    Color.clear
      .frame(width: width, height: height)
      .overlay(alignment: .bottom) {
        if still {
          HareSprite(rest, height: height)
        } else {
          TimelineView(.animation(paused: isPaused)) { _ in
            let now = CACurrentMediaTime()
            let breath = IdleMotion.breathing(at: now)
            HareSprite(
              HareFrame(.idle, IdleMotion.frame(at: now), friend: friend, look: look),
              height: height
            )
            .scaleEffect(x: breath.x, y: breath.y, anchor: .bottom)
          }
        }
      }
      .accessibilityHidden(true)
  }
}
