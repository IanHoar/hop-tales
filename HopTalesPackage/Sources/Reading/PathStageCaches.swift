import Content
import DesignSystem
import Foundation
import World

@MainActor
final class PathCache {
  private struct Key: Equatable {
    let story: String
    let friend: Friend
    let geometry: ReadingGeometry
  }

  private var key: Key?
  private var cached: WordPath?

  func path(for story: Story, friend: Friend, geometry: ReadingGeometry) -> WordPath {
    let key = Key(story: story.id, friend: friend, geometry: geometry)
    if key == self.key, let cached { return cached }
    let path = WordPath(
      sentences: story.sentences.map(\.words),
      geometry: geometry,
      style: WorldStyle.of(friend)
    )
    self.key = key
    cached = path
    return path
  }
}

@MainActor
final class HopClock {
  static let frameBudget: TimeInterval = 1.0 / 30

  private var started: TimeInterval = 0
  private var lost: TimeInterval = 0
  private var awaitingFirstFrame = false

  func began(at time: TimeInterval) {
    started = time
    lost = 0
    awaitingFirstFrame = true
  }

  func time(at now: TimeInterval) -> TimeInterval {
    if awaitingFirstFrame {
      awaitingFirstFrame = false
      lost = max(0, now - started - Self.frameBudget)
    }
    return now - lost
  }
}
