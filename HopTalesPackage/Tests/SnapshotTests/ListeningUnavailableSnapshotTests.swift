import SnapshotTesting
import SpeechRecognition
import SwiftUI
import Testing

@testable import Reading

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff))
struct ListeningUnavailableSnapshotTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func theMicrophoneIsOff(scheme: ColorScheme) {
    expectSnapshot(of: ListeningUnavailablePreview(authorization: .denied), scheme: scheme)
  }

  @Test(arguments: [ColorScheme.light, .dark])
  func theDeviceCannotListen(scheme: ColorScheme) {
    expectSnapshot(of: ListeningUnavailablePreview(authorization: .unsupported), scheme: scheme)
  }
}
