import Testing

@testable import Content

struct PlusTests {
  @Test func everyLevelOneStoryIsFree() {
    let free = StoryLibrary.all.filter(\.isFree).map(\.id)
    #expect(free == ["meadow-walk", "bob-bug", "big-nap", "mud-and-jam"])
    #expect(StoryLibrary.all.allSatisfy { $0.isFree == ($0.level == 1) })
  }

  @Test func storiesAboveLevelOneLockWithoutPlus() {
    let locked = StoryLibrary.all.filter { Plus.isLocked($0, isPlus: false, locksStories: true) }
    #expect(!locked.isEmpty)
    #expect(locked.allSatisfy { $0.level > 1 })
    #expect(locked.count == StoryLibrary.all.count { $0.level > 1 })
  }

  @Test func levelOneNeverLocks() {
    let free = StoryLibrary.all.filter { $0.level == 1 }
    #expect(free.allSatisfy { !Plus.isLocked($0, isPlus: false, locksStories: true) })
  }

  @Test func plusOpensEveryStory() {
    #expect(StoryLibrary.all.allSatisfy { !Plus.isLocked($0, isPlus: true, locksStories: true) })
  }

  @Test func theSwitchOffLocksNothing() {
    #expect(StoryLibrary.all.allSatisfy { !Plus.isLocked($0, isPlus: false, locksStories: false) })
  }

  @Test func onboardingOffersPlusOnceToAReaderWithoutIt() {
    let fresh = Profile(childName: "Maya")
    #expect(Plus.offersAtOnboarding(fresh, isPlus: false, locksStories: true))
    #expect(!Plus.offersAtOnboarding(fresh, isPlus: true, locksStories: true))
    let offered = Profile(childName: "Maya", plusOffered: true)
    #expect(!Plus.offersAtOnboarding(offered, isPlus: false, locksStories: true))
  }

  @Test func theSwitchOffSkipsTheOnboardingOffer() {
    #expect(!Plus.offersAtOnboarding(Profile(), isPlus: false, locksStories: false))
    #expect(Plus.offersAtOnboarding(Profile(), isPlus: false))
  }

  @Test func appStoreProductsMapOntoPlans() {
    #expect(PlusPlan(appStoreProductID: "com.hoptales.plus.monthly") == .monthly)
    #expect(PlusPlan(appStoreProductID: "com.hoptales.plus.yearly") == .yearly)
    #expect(PlusPlan(appStoreProductID: "com.hoptales.plus.weekly") == nil)
    #expect(PlusPlan.appStoreGroup == "hop_tales_plus")
    #expect(
      PlusPlan.allCases.allSatisfy { PlusPlan(appStoreProductID: $0.appStoreProductID) == $0 }
    )
  }

  @Test func playBasePlansMapOntoPlans() {
    #expect(PlusPlan(playProductID: "hop_tales_plus", basePlanID: "monthly") == .monthly)
    #expect(PlusPlan(playProductID: "hop_tales_plus", basePlanID: "yearly") == .yearly)
    #expect(PlusPlan(playProductID: "hop_tales_plus", basePlanID: "weekly") == nil)
    #expect(PlusPlan(playProductID: "com.hoptales.plus.monthly", basePlanID: "monthly") == nil)
    #expect(
      PlusPlan.allCases.allSatisfy {
        PlusPlan(playProductID: PlusPlan.playProductID, basePlanID: $0.playBasePlanID) == $0
      }
    )
  }

  @Test func thePaywallLeadsWithTheYearlyPlan() {
    #expect(PlusPlan.paywallOrder == [.yearly, .monthly])
    #expect(PlusPlan.yearly.months == 12)
    #expect(PlusPlan.monthly.months == 1)
  }
}
