import Foundation
import Testing

@testable import Content

struct PurchasesClientTests {
  let now = Date(timeIntervalSince1970: 1_800_000_000)

  @Test func aVerifiedPlusTransactionIsPlus() {
    #expect(PlusTransaction.isPlus([PlusTransaction(productID: "com.hoptales.plus.monthly")]))
    #expect(PlusTransaction.isPlus([PlusTransaction(productID: "com.hoptales.plus.yearly")]))
  }

  @Test func noTransactionsIsNotPlus() {
    #expect(!PlusTransaction.isPlus([]))
  }

  @Test func anUnverifiedTransactionIsNotPlus() {
    let unverified = PlusTransaction(productID: "com.hoptales.plus.yearly", isVerified: false)
    #expect(!PlusTransaction.isPlus([unverified]))
  }

  @Test func aRevokedTransactionIsNotPlus() {
    let refunded = PlusTransaction(productID: "com.hoptales.plus.yearly", revocationDate: now)
    #expect(!PlusTransaction.isPlus([refunded]))
  }

  @Test func anotherProductIsNotPlus() {
    #expect(!PlusTransaction.isPlus([PlusTransaction(productID: "com.hoptales.tip")]))
  }

  @Test func aFamilySharedTransactionCounts() {
    let shared = PlusTransaction(productID: "com.hoptales.plus.monthly", isFamilyShared: true)
    #expect(PlusTransaction.isPlus([shared]))
  }

  @Test func oneGoodTransactionIsEnough() {
    let transactions = [
      PlusTransaction(productID: "com.hoptales.plus.monthly", revocationDate: now),
      PlusTransaction(productID: "com.hoptales.plus.yearly")
    ]
    #expect(PlusTransaction.isPlus(transactions))
  }

  @Test func thePlanIsCheckedAgainWhenTheLatestOneRunsOut() {
    let soon = now.addingTimeInterval(60)
    let later = now.addingTimeInterval(3_600)
    let transactions = [
      PlusTransaction(productID: "com.hoptales.plus.monthly", expirationDate: soon),
      PlusTransaction(productID: "com.hoptales.plus.yearly", expirationDate: later),
      PlusTransaction(productID: "com.hoptales.plus.yearly", revocationDate: now)
    ]
    #expect(PlusTransaction.nextCheck(transactions, after: now) == later)
  }

  @Test func aPlanInItsGracePeriodSetsNoCheck() {
    let lapsed = PlusTransaction(
      productID: "com.hoptales.plus.monthly",
      expirationDate: now.addingTimeInterval(-60)
    )
    #expect(PlusTransaction.isPlus([lapsed]))
    #expect(PlusTransaction.nextCheck([lapsed], after: now) == nil)
  }

  @Test func theFakeReportsItsValue() async {
    var values: [Bool] = []
    for await isPlus in PurchasesClient.fixed(true).isPlus() { values.append(isPlus) }
    #expect(values == [true])
  }

  @Test func theStreamingFakeFollowsAPurchaseAndARefund() async {
    let (stream, continuation) = AsyncStream.makeStream(of: Bool.self)
    for value in [false, true, false] { continuation.yield(value) }
    continuation.finish()
    var values: [Bool] = []
    for await isPlus in PurchasesClient.streaming(stream).isPlus() { values.append(isPlus) }
    #expect(values == [false, true, false])
  }

  @Test func onlyLevelOneIsOpenWithoutPlus() {
    #expect(Plus.locksStories)
    #expect(StoryLibrary.all.allSatisfy { Plus.isLocked($0, isPlus: false) == ($0.level != 1) })
    #expect(StoryLibrary.all.allSatisfy { !Plus.isLocked($0, isPlus: true) })
  }
}
