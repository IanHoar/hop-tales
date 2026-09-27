import Testing

@testable import Content

@Suite(.everyLookPainted)
struct WardrobeTests {
  @Test(.noLooksPainted) func onlyFullyPaintedLooksAreOffered() {
    for friend in Friend.allCases {
      #expect(WardrobeLibrary.items(for: friend).isEmpty, "\(friend)")
    }
  }

  @Test func everyFriendWearsFiveOfTheirWardrobeAndBobHisBowToo() {
    #expect(WardrobeLibrary.all[.hare]?.count == 12)
    #expect(WardrobeLibrary.all[.bunny]?.count == 9)
    #expect(WardrobeLibrary.items(for: .bunny).count == 6)
    for friend in Friend.allCases where friend != .bunny {
      #expect(WardrobeLibrary.items(for: friend).count == 5, "\(friend)")
      if friend != .hare { #expect(WardrobeLibrary.all[friend]?.count == 8, "\(friend)") }
    }
  }

  @Test func meetingAFriendGivesTheirFirstItemAndEachBasketTheNext() {
    var progress = Progress(journey: Journey(starting: .hare))
    #expect(progress.unlockedCount(for: .hare) == 1)
    #expect(progress.unlockedCount(for: .frog) == 0)
    progress.baskets[.hare, default: Basket()].filled = 2
    #expect(progress.unlockedCount(for: .hare) == 3)
    #expect(progress.newestItem(for: .hare)?.id == "crown")
  }

  @Test func onlyUnlockedItemsCanBeWornAndOneItemPerSlot() throws {
    var progress = Progress(journey: Journey(starting: .hare))
    let items = WardrobeLibrary.items(for: .hare)
    progress.wear(items[1], on: .hare)
    #expect(progress.outfit(for: .hare).isEmpty)
    progress.wear(items[0], on: .hare)
    #expect(progress.outfit(for: .hare) == [items[0]])
    progress.baskets[.hare, default: Basket()].filled = 1
    progress.wear(items[1], on: .hare)
    #expect(progress.outfit(for: .hare) == [items[1]])
    progress.takeOff(items[1].slot, from: .hare)
    #expect(progress.outfit(for: .hare).isEmpty)
  }

  @Test func bobStartsTheJourneyInHisBow() throws {
    let progress = Progress()
    let bow = try #require(WardrobeLibrary.items(for: .bunny).first)
    #expect(bow.id == "bow")
    #expect(bow.slot == .head)
    #expect(WardrobeLibrary.startingItem(for: .bunny) == bow)
    #expect(progress.isUnlocked(bow, for: .bunny))
    #expect(progress.outfit(for: .bunny) == [bow])
    #expect(progress.newestItem(for: .bunny) == bow)
    #expect(WardrobeLibrary.startingItem(for: .hare) == nil)
    #expect(Progress(journey: Journey(starting: .hare)).outfit(for: .hare).isEmpty)
  }

  @Test func anotherHatReplacesBobsBow() throws {
    var progress = Progress()
    progress.baskets[.bunny, default: Basket()].filled = 1
    let crown = try #require(WardrobeLibrary.items(for: .bunny).first { $0.id == "bluebell-crown" })
    progress.wear(crown, on: .bunny)
    #expect(progress.outfit(for: .bunny) == [crown])
    progress.takeOff(.head, from: .bunny)
    #expect(progress.outfit(for: .bunny).isEmpty)
  }

  @Test func takingOffBobsBowLeavesHimBare() {
    var bowOff = Progress()
    bowOff.takeOff(.head, from: .bunny)
    #expect(bowOff.outfits[.bunny] == [:])
    #expect(bowOff.outfit(for: .bunny).isEmpty)

    var justMe = Progress()
    justMe.undress(.bunny)
    #expect(justMe.outfits[.bunny] == [:])
    #expect(justMe.outfit(for: .bunny).isEmpty)
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
    #expect(moment.unlockedItem?.id == "bluebell-crown")
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
