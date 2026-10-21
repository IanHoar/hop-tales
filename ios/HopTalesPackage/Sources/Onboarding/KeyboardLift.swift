import SwiftUI
import UIKit

struct KeyboardLift: ViewModifier {
  @State private var frame = CGRect.zero
  @State private var keyboardTop = CGFloat.infinity

  func body(content: Content) -> some View {
    content
      .padding(.bottom, lift)
      .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame = $0 }
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
    max(0, frame.maxY - keyboardTop)
  }
}

extension View {
  func liftsAboveKeyboard() -> some View {
    modifier(KeyboardLift())
  }
}
