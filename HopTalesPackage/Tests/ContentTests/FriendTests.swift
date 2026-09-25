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
  }

  @Test func aProfileRoundTripsWithItsFriend() throws {
    let profile = Profile(childName: "Wren", startingFriend: .hare, accent: .australian)
    let decoded = try JSONDecoder().decode(Profile.self, from: JSONEncoder().encode(profile))
    #expect(decoded == profile)
  }
}
