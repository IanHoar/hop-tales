import Content
import GrownUps

extension Home.State {
  var keepGoing: StoryStanding? {
    standings
      .filter { !isLocked($0.story) }
      .keepGoing(startingAt: progress.journey.activeFriend.startingStoryID)
      ?? bigStoryWaiting.map { StoryStanding(story: $0, progress: progress) }
  }

  public var lockedLevels: [Friend] {
    Plus.lockedLevels(
      above: progress.journey.activeFriend.level, isPlus: isPlus, locksStories: locksStories
    )
  }

  var bigStoryWaiting: Story? {
    guard let story = progress.journey.bigStory, !isLocked(story) else { return nil }
    return story
  }

  var newFriend: Friend? {
    bigStoryWaiting == nil ? nil : progress.journey.nextFriend
  }

  var nextLevels: [Friend] {
    let locked = lockedLevels
    return locked.isEmpty ? Plus.levels(above: progress.journey.level) : locked
  }

  func standing(of friend: Friend) -> LevelRow.Standing {
    if lockedLevels.contains(friend) { return .locked }
    if friend == progress.journey.nextFriend, let story = bigStoryWaiting { return .ready(story) }
    return .ahead
  }

  var plusWelcome: PlusWelcome? {
    let journey = progress.journey
    let next = standings.keepGoing(startingAt: journey.activeFriend.startingStoryID)
    guard let friend = journey.nextFriend else {
      return next.map {
        PlusWelcome(story: $0.story, friend: $0.story.friend, meetsFriend: false)
      }
    }
    if let big = journey.bigStory {
      return PlusWelcome(story: big, friend: friend, meetsFriend: true)
    }
    return next.map { PlusWelcome(story: $0.story, friend: friend, meetsFriend: false) }
  }
}
