import Foundation
import Testing

@testable import Content

struct FriendTests {
  @Test func theFriendsAreTheSevenLevelsInOrder() {
    #expect(Friend.allCases.map(\.level) == Array(1...7))
    #expect(Friend.starters == [.bunny, .hare, .frog])
  }

  @Test func eachStartingFriendBeginsOnTheStoryItsLevelUsedTo() {
    #expect(Friend.starters.map(\.startingStoryID) == StoryLibrary.all.prefix(3).map(\.id))
    for friend in Friend.starters {
      #expect(Friend(startingStoryID: friend.startingStoryID) == friend)
    }
  }

  @Test func aProfileSavedBeforeFriendsKeepsItsStartingPoint() throws {
    let saved = """
      {"childName":"Maya","startingStoryID":"\(StoryLibrary.all[2].id)","accent":"en-GB"}
      """
    let profile = try JSONDecoder().decode(Profile.self, from: Data(saved.utf8))
    #expect(profile.startingFriend == .frog)
    #expect(profile.startingStoryID == StoryLibrary.all[2].id)
    #expect(profile.accent == .british)
    #expect(profile.theme == .device)
  }

  @Test func aProfileRoundTripsWithItsFriend() throws {
    let profile = Profile(
      childName: "Wren", startingFriend: .hare, accent: .australian, theme: .dark
    )
    let decoded = try JSONDecoder().decode(Profile.self, from: JSONEncoder().encode(profile))
    #expect(decoded == profile)
  }

  @Test func theAccentFollowsTheDeviceRegion() {
    #expect(Profile.Accent(region: .canada) == .canadian)
    #expect(Profile.Accent(region: .unitedStates) == .american)
    #expect(Profile.Accent(region: .unitedKingdom) == .british)
    #expect(Profile.Accent(region: .australia) == .australian)
    #expect(Profile.Accent(region: .france) == .canadian)
    #expect(Profile.Accent(region: nil) == .canadian)
  }
}

struct LevelContentTests {
  @Test(arguments: 1...7)
  func everyLevelHasFourStoriesTwoOfThemStretch(level: Int) {
    let stories = StoryLibrary.stories(at: level)
    #expect(stories.count == 4)
    #expect(stories.filter(\.stretch).count == 2)
  }

  @Test(arguments: 2...7)
  func everyLevelUpHasABigStoryWithNoBigWords(level: Int) throws {
    let story = try #require(StoryLibrary.bigStory(at: level))
    #expect(!story.stretch)
    #expect(story.sentences.allSatisfy { $0.words.allSatisfy { !$0.big } })
  }

  @Test func theFirstLevelHasNoBigStory() {
    #expect(StoryLibrary.bigStory(at: 1) == nil)
  }

  @Test(arguments: 1...7)
  func regularStoriesCarryBigWords(level: Int) {
    for story in StoryLibrary.stories(at: level) {
      #expect(story.sentences.contains { $0.words.contains(where: \.big) }, "\(story.id)")
    }
  }

  @Test func storyIDsAreUnique() {
    let ids = StoryLibrary.all.map(\.id)
    #expect(Set(ids).count == ids.count)
  }

  @Test func theShelfStopsAtTheOnboardingLevelsAndLeavesOutBigStories() {
    let shelf = StoryLibrary.shelf(upTo: 3)
    #expect(shelf.count == 12)
    #expect(shelf.allSatisfy { $0.level <= 3 && !$0.isBigStory })
  }

  @Test func aStoryOnlyNamesItsOwnLevelsFriend() {
    let names = Set(Friend.allCases.map(\.name))
    for story in StoryLibrary.all where !(story.isBigStory && story.level == Levels.top) {
      for word in story.sentences.flatMap(\.words) where names.contains(word.text) {
        #expect(word.text == story.friend.name, "\(story.id) names \(word.text)")
      }
    }
  }

  @Test func eachStoryBelongsToItsLevelsFriend() {
    #expect(StoryLibrary["oggy-kite"]?.friend == .frog)
    #expect(StoryLibrary["bartholomew-big-story"]?.friend == .grasshopper)
  }
}
