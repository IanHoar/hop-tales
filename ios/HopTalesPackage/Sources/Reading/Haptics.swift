import UIKit

enum Haptics {
  @MainActor
  static func sentenceCompleted() {
    guard UIDevice.current.userInterfaceIdiom == .phone else { return }
    UINotificationFeedbackGenerator().notificationOccurred(.success)
  }

  @MainActor
  static func wordRecognised() {
    guard UIDevice.current.userInterfaceIdiom == .phone else { return }
    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
  }
}
