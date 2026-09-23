import SwiftUI

extension View {
  public func inkHalo(_ width: CGFloat, color: Color = Palette.outline) -> some View {
    shadow(color: color, radius: 0, x: width, y: 0)
      .shadow(color: color, radius: 0, x: -width, y: 0)
      .shadow(color: color, radius: 0, x: 0, y: width)
      .shadow(color: color, radius: 0, x: 0, y: -width)
      .shadow(color: color, radius: 0, x: width * 0.7, y: width * 0.7)
      .shadow(color: color, radius: 0, x: -width * 0.7, y: -width * 0.7)
  }
}
