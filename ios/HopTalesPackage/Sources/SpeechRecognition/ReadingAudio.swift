import AVFoundation
import Synchronization

public enum ReadingAudio {
  private static let isActive = Mutex(false)

  public static func activate() throws {
    try isActive.withLock { isActive in
      guard !isActive else { return }
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(
        .playAndRecord,
        mode: .measurement,
        options: [.defaultToSpeaker, .duckOthers, .allowBluetoothHFP]
      )
      try session.setActive(true, options: .notifyOthersOnDeactivation)
      isActive = true
    }
  }

  public static func deactivate() {
    isActive.withLock { isActive in
      guard isActive else { return }
      try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
      isActive = false
    }
  }

  public static var isReading: Bool { isActive.withLock { $0 } }
}
