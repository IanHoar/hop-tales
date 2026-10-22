import Foundation

extension Progress {
  public var hasFinishedLevelOne: Bool {
    StoryLibrary.stories(at: Plus.freeLevel).allSatisfy {
      (completedSentences[$0.id] ?? 0) >= $0.sentences.count
    }
  }

  public mutating func celebrateLevelOne(
    after story: Story,
    in moments: [JourneyMoment],
    isPlus: Bool,
    locksStories: Bool = Plus.locksStories
  ) -> [JourneyMoment] {
    guard
      locksStories, !isPlus, !levelOneCelebrated, story.isFree, !story.isBigStory,
      hasFinishedLevelOne
    else { return moments }
    levelOneCelebrated = true
    var kept = moments.filter { moment in
      if case .bigStoryReady = moment { return false }
      return true
    }
    kept.insert(.levelOneFinished, at: kept.firstIndex(where: \.isCallout) ?? kept.endIndex)
    return kept
  }
}
