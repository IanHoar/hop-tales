import Testing

@testable import Content

struct WardrobeTests {
  @Test func everyFriendHasTheirWardrobe() {
    #expect(WardrobeLibrary.items(for: .hare).count == 12)
    for friend in Friend.allCases where friend != .hare {
      #expect(WardrobeLibrary.items(for: friend).count == 8, "\(friend)")
    }
  }

  @Test func meetingAFriendGivesTheirFirstItemAndEachBasketTheNext() {
    var progress = Progress(journey: Journey(starting: .hare))
    #expect(progress.unlockedCount(for: .hare) == 1)
    #expect(progress.unlockedCount(for: .frog) == 0)
    progress.baskets[.hare, default: Basket()].filled = 2
    #expect(progress.unlockedCount(for: .hare) == 3)
    #expect(progress.newestItem(for: .hare)?.id == "neckerchief")
  }

  @Test func onlyUnlockedItemsCanBeWornAndOneItemPerSlot() throws {
    var progress = Progress(journey: Journey(starting: .bunny))
    let items = WardrobeLibrary.items(for: .bunny)
    progress.wear(items[1], on: .bunny)
    #expect(progress.outfit(for: .bunny).isEmpty)
    progress.wear(items[0], on: .bunny)
    #expect(progress.outfit(for: .bunny) == [items[0]])
    progress.baskets[.bunny, default: Basket()].filled = 1
    progress.wear(items[1], on: .bunny)
    #expect(progress.outfit(for: .bunny) == [items[1]])
    progress.takeOff(.head, from: .bunny)
    #expect(progress.outfit(for: .bunny).isEmpty)
  }

  @Test func aFriendWearsOneLookAtATime() throws {
    var progress = Progress(journey: Journey(starting: .hare))
    let items = WardrobeLibrary.items(for: .hare)
    progress.baskets[.hare, default: Basket()].filled = items.count
    let first = try #require(items.first)
    let other = try #require(items.first { $0.slot != first.slot })
    progress.wear(first, on: .hare)
    progress.wear(other, on: .hare)
    #expect(progress.outfit(for: .hare) == [other])
  }

  @Test func aFullBasketNamesTheItemItUnlocks() {
    let moment = JourneyMoment.basketFull(.bunny, number: 1)
    #expect(moment.unlockedItem?.id == "bonnet")
  }

  @Test func pairedItemsHaveTwoParts() throws {
    let mittens = try #require(WardrobeLibrary.items(for: .crab).first { $0.id == "claw-mittens" })
    #expect(mittens.parts.count == 2)
    #expect(mittens.slot == .claws)
  }
}
