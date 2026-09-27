import Testing

@testable import Content

@Suite(.everyLookPainted)
struct WardrobeTests {
  @Test(.noLooksPainted) func onlyFullyPaintedLooksAreOffered() {
    for friend in Friend.allCases {
      #expect(WardrobeLibrary.items(for: friend).isEmpty, "\(friend)")
    }
  }

  @Test func everyFriendUnlocksFiveOfTheirWardrobeAndBobSkipAndOggyStartWithAnother() {
    #expect(WardrobeLibrary.all[.hare]?.count == 13)
    #expect(WardrobeLibrary.all[.bunny]?.count == 9)
    #expect(WardrobeLibrary.all[.frog]?.count == 9)
    for friend in Friend.allCases {
      let starts = WardrobeLibrary.starting[friend] != nil
      #expect(WardrobeLibrary.items(for: friend).count == (starts ? 6 : 5), "\(friend)")
      #expect(WardrobeLibrary.unlockable(for: friend).count == 5, "\(friend)")
      if friend != .hare, friend != .bunny, friend != .frog {
        #expect(WardrobeLibrary.all[friend]?.count == 8, "\(friend)")
      }
    }
  }

  @Test func meetingAFriendGivesTheirFirstItemAndEachBasketTheNext() {
    var progress = Progress(journey: Journey(starting: .hare))
    #expect(progress.unlockedCount(for: .hare) == 1)
    #expect(progress.unlockedCount(for: .frog) == 0)
    #expect(progress.newestItem(for: .hare)?.id == "straw")
    progress.baskets[.hare, default: Basket()].filled = 2
    #expect(progress.unlockedCount(for: .hare) == 3)
    #expect(progress.newestItem(for: .hare)?.id == "crown")
  }

  @Test func onlyUnlockedItemsCanBeWornAndOneItemPerSlot() throws {
    var progress = Progress(journey: Journey(starting: .crow))
    let items = WardrobeLibrary.items(for: .crow)
    progress.wear(items[1], on: .crow)
    #expect(progress.outfit(for: .crow).isEmpty)
    progress.wear(items[0], on: .crow)
    #expect(progress.outfit(for: .crow) == [items[0]])
    progress.baskets[.crow, default: Basket()].filled = 1
    progress.wear(items[1], on: .crow)
    #expect(progress.outfit(for: .crow) == [items[1]])
    progress.takeOff(items[1].slot, from: .crow)
    #expect(progress.outfit(for: .crow).isEmpty)
  }

  @Test(arguments: [
    (Friend.bunny, "bow", Slot.head), (.hare, "scarf", .neck), (.frog, "neckerchief", .neck)
  ])
  func startingItemsAreWornUntilSomethingElseIsChosen(
    friend: Friend, id: String, slot: Slot
  ) throws {
    let item = try #require(WardrobeLibrary.startingItem(for: friend))
    #expect(item.id == id)
    #expect(item.slot == slot)
    #expect(WardrobeLibrary.items(for: friend).first == item)
    #expect(!WardrobeLibrary.unlockable(for: friend).contains(item))
    let fresh = Progress()
    #expect(fresh.isUnlocked(item, for: friend))
    #expect(fresh.outfit(for: friend) == [item])
    #expect(WardrobeLibrary.startingItem(for: .crow) == nil)
    #expect(Progress(journey: Journey(starting: .crow)).outfit(for: .crow).isEmpty)
  }

  @Test func startingItemsLeaveTheUnlockOrderAlone() throws {
    let bow = try #require(WardrobeLibrary.startingItem(for: .bunny))
    var progress = Progress()
    #expect(progress.newestItem(for: .bunny)?.id == "bluebell-crown")
    #expect(progress.unlockedCount(for: .bunny) == 1)
    progress.baskets[.bunny, default: Basket()].filled = 1
    #expect(progress.newestItem(for: .bunny)?.id == "bonnet")
    #expect(progress.isUnlocked(bow, for: .bunny))
  }

  @Test func anotherHatReplacesBobsBow() throws {
    var progress = Progress()
    let crown = try #require(WardrobeLibrary.items(for: .bunny).first { $0.id == "bluebell-crown" })
    progress.wear(crown, on: .bunny)
    #expect(progress.outfit(for: .bunny) == [crown])
    progress.takeOff(.head, from: .bunny)
    #expect(progress.outfit(for: .bunny).isEmpty)
  }

  @Test func anythingElseReplacesSkipsScarf() throws {
    var progress = Progress(journey: Journey(starting: .hare))
    let straw = try #require(WardrobeLibrary.items(for: .hare).first { $0.id == "straw" })
    progress.wear(straw, on: .hare)
    #expect(progress.outfit(for: .hare) == [straw])
  }

  @Test(arguments: [(Friend.bunny, Slot.head), (.hare, .neck)])
  func takingOffAStartingItemLeavesThemBare(friend: Friend, slot: Slot) {
    var itemOff = Progress()
    itemOff.takeOff(slot, from: friend)
    #expect(itemOff.outfits[friend] == [:])
    #expect(itemOff.outfit(for: friend).isEmpty)

    var justMe = Progress()
    justMe.undress(friend)
    #expect(justMe.outfits[friend] == [:])
    #expect(justMe.outfit(for: friend).isEmpty)
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

struct PaintedLooks: TestTrait, SuiteTrait, TestScoping {
  let painted: [Friend: Set<String>]

  func provideScope(
    for test: Test, testCase: Test.Case?, performing function: () async throws -> Void
  ) async throws {
    try await WardrobeLibrary.$painted.withValue(painted, operation: function)
  }
}

extension Trait where Self == PaintedLooks {
  static var everyLookPainted: Self {
    PaintedLooks(painted: WardrobeLibrary.wearable.mapValues(Set.init))
  }

  static var noLooksPainted: Self { PaintedLooks(painted: [:]) }
}
