import Content
import DesignSystem
import SwiftUI
import World

struct PaperSheet: View {
  static let shape = Deckle(seed: 29, jitter: 3, step: 14)

  var body: some View {
    Self.shape
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

struct PaywallScene: View {
  static let friend = Friend.grasshopper
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    GeometryReader { proxy in
      MeadowBackdrop(
        progress: 900,
        mood: Mood(sky: colorScheme == .dark ? .night : .day),
        world: Self.friend
      )
      .frame(width: proxy.size.width * 2, height: proxy.size.height * 2)
      .scaleEffect(0.5, anchor: .topLeading)
    }
    .overlay(alignment: .bottom) {
      IdleFriend(Self.friend, look: nil, height: 84)
        .shadow(color: Paper.shadow, radius: 4, y: 3)
        .padding(.bottom, 44)
    }
    .frame(height: 180)
    .padding(.horizontal, -24)
    .padding(.top, -24)
    .padding(.bottom, 6)
    .accessibilityHidden(true)
  }
}

struct PaywallPitch: View {
  static let benefits = [
    "Unlock all reading levels",
    "More characters",
    "More stories",
    "More costumes"
  ]

  var body: some View {
    VStack(spacing: 8) {
      PaywallScene()
      PaywallTitle()
      VStack(alignment: .leading, spacing: 6) {
        ForEach(Self.benefits, id: \.self) { benefit in
          Label(benefit, systemImage: "checkmark")
            .font(Typography.ui(17, weight: .medium))
            .foregroundStyle(Paper.ink)
        }
      }
      .padding(.vertical, 4)
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
