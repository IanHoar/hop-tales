import Content
import Foundation

public struct StoryStanding: Equatable, Sendable, Identifiable {
  public enum Standing: Equatable, Sendable {
    case unread
    case inProgress(remaining: Int)
    case finished
  }

  public var story: Story
  public var standing: Standing

  public var id: String { story.id }

  public init(story: Story, progress: Content.Progress) {
    self.story = story
    let completed = progress.completedSentences[story.id] ?? 0
    let total = story.sentences.count
    if completed >= total {
      standing = .finished
    } else if completed > 0 {
      standing = .inProgress(remaining: total - completed)
    } else {
      standing = .unread
    }
  }

  public var subtitle: String {
    let sentences = "\(story.sentences.count) sentences"
    switch standing {
    case .unread: return sentences
    case .inProgress(let remaining): return "\(sentences) · \(remaining) to go"
    case .finished: return "\(sentences) · finished"
    }
  }

  public var isCurrent: Bool {
    if case .inProgress = standing { return true }
    return false
  }
}

extension Array where Element == StoryStanding {
  public var keepGoing: StoryStanding? {
    keepGoing(startingAt: nil)
  }

  public func keepGoing(startingAt storyID: String?) -> StoryStanding? {
    first(where: \.isCurrent)
      ?? first { $0.story.id == storyID && $0.standing == .unread }
      ?? first { $0.standing == .unread }
  }
}
