import Foundation
import Testing

@testable import Content

struct PlusStatusTests {
  static let march3 = Date(timeIntervalSince1970: 1_772_496_000)
  static let utc = TimeZone(identifier: "UTC")!
  static let monthly = PlusPlan.monthly.appStoreProductID

  private func line(_ kind: PlusStatus.Kind) -> String {
    PlusStatus(kind).line(locale: Locale(identifier: "en_CA"), timeZone: Self.utc)
  }

  private func renewal(
    _ state: PlusRenewal.State,
    productID: String = Self.monthly,
    isVerified: Bool = true,
    willAutoRenew: Bool = true,
    isFamilyShared: Bool = false
  ) -> PlusRenewal {
    PlusRenewal(
      state: state,
      transactionID: 7,
      productID: productID,
      isVerified: isVerified,
      willAutoRenew: willAutoRenew,
      periodEnds: Self.march3,
      isFamilyShared: isFamilyShared
    )
  }

  @Test func theStatusIsInPlainWords() {
    #expect(line(.free) == "Free: the Level 1 stories")
    #expect(line(.plus) == "Plus: every story")
    #expect(line(.renews(Self.march3)) == "Plus, renews 3 March")
    #expect(line(.renews(nil)) == "Plus, renews automatically")
    #expect(line(.ends(Self.march3)) == "Plus, ends 3 March")
    #expect(line(.ends(nil)) == "Plus, ends at the end of this period")
    #expect(line(.familyShared) == "Plus, shared by your family")
    #expect(line(.paymentProblem) == "There's a problem with your payment")
    #expect(line(.pending) == "Waiting for your payment to go through")
  }

  @Test func onlyAFreeReaderIsOfferedSubscribe() {
    #expect(PlusStatus.free.canSubscribe)
    #expect(!PlusStatus.free.canManage)
    let kinds: [PlusStatus.Kind] = [.plus, .renews(nil), .ends(nil), .familyShared, .paymentProblem]
    for kind in kinds {
      #expect(!PlusStatus(kind).canSubscribe)
      #expect(PlusStatus(kind).canManage)
    }
  }

  @Test func aPaymentProblemSaysWhereToFixIt() {
    #expect(PlusStatus(.paymentProblem).detail != nil)
    #expect(PlusStatus(.renews(nil)).detail == nil)
  }

  @Test func aRenewingSubscriptionRenewsWhenItsPeriodEnds() {
    let status = PlusStatus.of([renewal(.subscribed)])
    #expect(status == PlusStatus(.renews(Self.march3), refundableTransactionID: 7))
    #expect(status?.canRequestRefund == true)
  }

  @Test func aCancelledSubscriptionEndsWhenItsPeriodEnds() {
    let status = PlusStatus.of([renewal(.subscribed, willAutoRenew: false)])
    #expect(status == PlusStatus(.ends(Self.march3), refundableTransactionID: 7))
  }

  @Test(arguments: [PlusRenewal.State.inGracePeriod, .inBillingRetry])
  func graceAndBillingRetryAreAPaymentProblem(state: PlusRenewal.State) {
    let status = PlusStatus.of([renewal(state)])
    #expect(status == PlusStatus(.paymentProblem, refundableTransactionID: 7))
  }

  @Test func aFamilySharedSubscriptionSaysSoAndIsNotRefundedHere() {
    let status = PlusStatus.of([renewal(.subscribed, isFamilyShared: true)])
    #expect(status == PlusStatus(.familyShared))
    #expect(status?.canRequestRefund == false)
  }

  @Test func ownSubscriptionComesBeforeTheFamilys() {
    let status = PlusStatus.of([
      renewal(.subscribed, isFamilyShared: true),
      renewal(.subscribed, willAutoRenew: false)
    ])
    #expect(status?.kind == .ends(Self.march3))
  }

  @Test(arguments: [PlusRenewal.State.expired, .revoked])
  func aLapsedOrRefundedSubscriptionIsFree(state: PlusRenewal.State) {
    #expect(PlusStatus.of([renewal(state)]) == .free)
  }

  @Test func unverifiedOrUnknownRenewalsTellNothing() {
    #expect(PlusStatus.of([]) == nil)
    #expect(PlusStatus.of([renewal(.subscribed, isVerified: false)]) == nil)
    #expect(PlusStatus.of([renewal(.subscribed, productID: "com.hoptales.other")]) == nil)
  }

  @Test func theEntitlementStandsInWhenTheStoreSaysNothing() {
    #expect(PlusStatus.resolved(isPlus: false, details: nil) == .free)
    #expect(PlusStatus.resolved(isPlus: true, details: nil) == PlusStatus(.plus))
    #expect(PlusStatus.resolved(isPlus: true, details: .free) == PlusStatus(.plus))
    let problem = PlusStatus(.paymentProblem, refundableTransactionID: 7)
    #expect(PlusStatus.resolved(isPlus: false, details: problem) == problem)
  }
}
