import ComposableArchitecture
import Content
import DesignSystem
import SwiftUI

#if DEBUG
struct PaywallPreview: View {
  var offers = PaywallOffers.loaded(PlusOffer.samples)
  var isPending = false
  var isSubscribed = false
  var work: Paywall.Work?
  var welcome: PlusWelcome?

  var body: some View {
    PaywallScreen(
      store: Store(initialState: state) {
        Paywall()
          .dependency(PurchasesClient.fake(offers: loaded))
      }
    )
      .frame(width: Metrics.phone.reference.width, height: Metrics.phone.reference.height)
  }

  private var loaded: [PlusOffer]? {
    guard case let .loaded(offers) = offers else { return nil }
    return offers
  }

  private var state: Paywall.State {
    var state = Paywall.State()
    state.offers = offers
    state.isPending = isPending
    state.isSubscribed = isSubscribed
    state.work = work
    state.welcome = welcome
    return state
  }
}

#Preview("Paywall") { PaywallPreview() }
#Preview("Paywall, store unavailable") { PaywallPreview(offers: .unavailable) }
#Preview("Paywall, waiting for the store") { PaywallPreview(isPending: true) }
#Preview("Paywall, subscribing") { PaywallPreview(work: .subscribing) }
#Preview("Paywall, welcome") {
  PaywallPreview(
    isSubscribed: true,
    welcome: PlusWelcome(story: StoryLibrary.bigStory(at: 2)!, friend: .hare, meetsFriend: true)
  )
}
#Preview("Paywall, welcome from settings") { PaywallPreview(isSubscribed: true) }
#endif
