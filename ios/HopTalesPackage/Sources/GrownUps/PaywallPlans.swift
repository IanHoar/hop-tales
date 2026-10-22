import Content
import DesignSystem
import StoreKit
import SwiftUI

struct PaperSheet: View {
  var body: some View {
    Deckle(seed: 29, jitter: 3, step: 14)
      .fill(Paper.paper)
      .shadow(color: Paper.shadow, radius: 8, y: 5)
  }
}

struct PaywallTitle: View {
  var body: some View {
    Text("Hop Tales Plus")
      .font(Typography.display(30))
      .foregroundStyle(Paper.ink)
      .multilineTextAlignment(.center)
      .accessibilityAddTraits(.isHeader)
  }
}

struct PaywallPitch: View {
  var body: some View {
    VStack(spacing: 8) {
      PaywallTitle()
      Text("Every story in the meadow, with a new one every month and something new each season.")
        .font(Typography.ui(17, weight: .medium))
        .foregroundStyle(Paper.ink)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
      Text("One subscription covers your whole family.")
        .font(Typography.ui(15))
        .foregroundStyle(Paper.muted)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

struct PlanList: View {
  let offers: [PlusOffer]
  let choose: (PlusPlan) -> Void

  var body: some View {
    VStack(spacing: 12) {
      ForEach(offers) { offer in
        PlanRow(offer: offer) { choose(offer.plan) }
      }
    }
  }
}

struct PlanRow: View {
  let offer: PlusOffer
  let action: () -> Void

  private var leads: Bool { offer.plan == .yearly }

  private var name: String {
    switch offer.plan {
    case .monthly: "Monthly"
    case .yearly: "Yearly"
    }
  }

  private var price: String {
    switch offer.plan {
    case .monthly: "\(offer.price) a month"
    case .yearly: "\(offer.price) a year"
    }
  }

  private var detail: String {
    if let monthly = offer.monthlyPrice { return "Just \(monthly) a month, the better value" }
    return "The flexible option"
  }

  var body: some View {
    Button(action: action) {
      HStack(alignment: .center, spacing: 12) {
        VStack(alignment: .leading, spacing: 3) {
          HStack(spacing: 8) {
            Text(name)
              .font(Typography.display(21))
              .foregroundStyle(Paper.ink)
              .fixedSize()
            if leads {
              Text("Best value")
                .font(Typography.ui(13, weight: .bold))
                .foregroundStyle(Paper.onRed)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Paper.red, in: Capsule())
                .fixedSize()
            }
          }
          Text(detail)
            .font(Typography.ui(14, weight: .medium))
            .foregroundStyle(Paper.muted)
            .fixedSize(horizontal: false, vertical: true)
        }
        Spacer(minLength: 8)
        Text(price)
          .font(Typography.ui(17, weight: .bold))
          .foregroundStyle(Paper.ink)
          .fixedSize()
      }
      .paperChoice(isSelected: leads)
    }
    .buttonStyle(.plain)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(name), \(price). \(detail).")
    .accessibilityAddTraits(.isButton)
  }
}

struct PaperPlansStyle<Footer: View>: SubscriptionStoreControlStyle {
  let footer: Footer

  func makeBody(configuration: Configuration) -> some View {
    let options = Dictionary(
      configuration.options.compactMap { option in
        PlusOffer(option.subscription).map { ($0.plan, (offer: $0, option: option)) }
      },
      uniquingKeysWith: { first, _ in first }
    )
    VStack(spacing: 18) {
      VStack(spacing: 12) {
        ForEach(PlusPlan.paywallOrder, id: \.self) { plan in
          if let choice = options[plan] {
            PlanRow(offer: choice.offer) { choice.option.subscribe() }
          }
        }
      }
      footer
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 18)
    .frame(maxWidth: 460)
  }
}
