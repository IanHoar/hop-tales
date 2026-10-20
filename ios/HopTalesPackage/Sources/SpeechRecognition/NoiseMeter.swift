import AVFoundation
import Foundation
import Synchronization

final class NoiseMeter: Sendable {
  static let silent: Double = -100
  static let blockLength: TimeInterval = 0.1
  static let window = 30
  static let floorRank = 0.1

  private struct Blocks {
    var levels: [Double] = []
    var squares: Double = 0
    var frames = 0
  }

  private let blocks = Mutex(Blocks())

  init() {}

  var floor: Double {
    blocks.withLock { Self.floor(of: $0.levels) }
  }

  func feed(_ buffer: AVAudioPCMBuffer) {
    guard let samples = buffer.floatChannelData?[0] else { return }
    let count = Int(buffer.frameLength)
    let blockFrames = max(1, Int(buffer.format.sampleRate * Self.blockLength))
    var squares: Double = 0
    for index in 0..<count {
      let sample = Double(samples[index])
      squares += sample * sample
    }
    add(squares: squares, frames: count, blockFrames: blockFrames)
  }

  func add(squares: Double, frames: Int, blockFrames: Int) {
    blocks.withLock { blocks in
      blocks.squares += squares
      blocks.frames += frames
      guard blocks.frames >= blockFrames else { return }
      blocks.levels.append(Self.decibels(meanSquare: blocks.squares / Double(blocks.frames)))
      if blocks.levels.count > Self.window { blocks.levels.removeFirst() }
      blocks.squares = 0
      blocks.frames = 0
    }
  }

  static func decibels(meanSquare: Double) -> Double {
    guard meanSquare > 0 else { return silent }
    return max(silent, 10 * log10(meanSquare))
  }

  static func floor(of levels: [Double]) -> Double {
    guard !levels.isEmpty else { return silent }
    let sorted = levels.sorted()
    return sorted[Int(Double(sorted.count - 1) * floorRank)]
  }
}
