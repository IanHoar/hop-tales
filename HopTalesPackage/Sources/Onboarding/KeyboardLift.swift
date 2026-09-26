import SwiftUI
import UIKit

struct KeyboardLift: ViewModifier {
  let topLimit: CGFloat
  @State private var frame = CGRect.zero
  @State private var keyboardTop = CGFloat.infinity

  func body(content: Content) -> some View {
    content
      .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame = $0 }
      .offset(y: -lift)
      .onReceive(
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
      ) { note in
        guard let end = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
          return
        }
        withAnimation(.easeOut(duration: 0.25)) { keyboardTop = end.minY }
      }
  }

  private var lift: CGFloat {
    let covered = max(0, frame.maxY - keyboardTop)
    return min(covered, max(0, frame.minY - topLimit))
  }
}

extension View {
  func liftsAboveKeyboard(keepingTopBelow topLimit: CGFloat) -> some View {
    modifier(KeyboardLift(topLimit: topLimit))
  }
}
