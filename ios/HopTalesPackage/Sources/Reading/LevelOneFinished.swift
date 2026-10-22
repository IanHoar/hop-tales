import Content
import DesignSystem
import GrownUps
import SwiftUI
import World

extension Reading {
  func levelOne(_ action: Action, _ state: inout State) -> Bool {
    switch action {
    case .askAGrownUpTapped:
      state.grownUp = GrownUpPaywall.State(seed: gateSeed.draw())
    case .grownUp(.gate(.closeTapped)), .grownUp(.paywall(.closeTapped)),
      .grownUp(.paywall(.tryLevelOneTapped)):
      state.grownUp = nil
    case .grownUp(.paywall(.subscribed)):
      state.grownUp = nil
      state.dismissCallout()
    case .levelOneKeepReadingTapped:
      state.dismissCallout()
      return state.callout == nil
    default:
      break
    }
    return false
  }
}

struct LevelOneCard: View {
  static let next = Friend.at(level: Plus.freeLevel + 1)

  let geometry: ReadingGeometry
  let askAGrownUp: () -> Void
  let keepReading: () -> Void

  private var words: String { Self.next.examples.joined(separator: ", ") }

  private var examples: Text {
    Text(words).font(Typography.word(geometry.path(17))).foregroundStyle(Paper.ink)
  }

  var body: some View {
    VStack(spacing: geometry.path(12)) {
      rosette
      Text("You finished Level \(Plus.freeLevel)!")
        .font(Typography.display(geometry.path(24)))
        .foregroundStyle(Paper.ink)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityAddTraits(.isHeader)
      nextFriend
      ViewThatFits(in: .horizontal) {
        HStack(spacing: geometry.path(10)) { buttons }
        VStack(spacing: geometry.path(10)) { buttons }
      }
      .padding(.top, geometry.path(4))
    }
    .padding(geometry.path(20))
    .frame(maxWidth: geometry.path(340))
    .background {
      Deckle(seed: 41, jitter: geometry.path(2.6), step: geometry.path(10))
        .fill(Paper.paper)
        .shadow(color: Paper.shadow, radius: geometry.path(10), y: geometry.path(6))
    }
    .rotationEffect(.degrees(-1))
    .accessibilityElement(children: .contain)
  }

  private var rosette: some View {
    ZStack {
      Sunburst(rays: 14)
        .fill(RadialGradient(
          colors: [Paper.wash.opacity(0.75), Paper.wash.opacity(0)],
          center: .center, startRadius: 0, endRadius: geometry.path(60)
        ))
        .frame(width: geometry.path(120), height: geometry.path(120))
      Sticker("collect-rosette", height: geometry.path(72))
      Text("\(Plus.freeLevel)")
        .font(Typography.display(geometry.path(24)))
        .foregroundStyle(Color(hex: 0x3B2A20))
        .offset(y: -geometry.path(7))
    }
    .rotationEffect(.degrees(6))
    .frame(height: geometry.path(84))
    .accessibilityHidden(true)
  }

  private var nextFriend: some View {
    HStack(spacing: geometry.path(12)) {
      FriendSticker(Self.next, height: geometry.path(72))
        .frame(width: geometry.path(72))
      VStack(alignment: .leading, spacing: geometry.path(3)) {
        Text("\(Self.next.name) is waiting")
          .font(Typography.display(geometry.path(18)))
          .foregroundStyle(Paper.ink)
        Text("Words like \(examples)")
        .font(Typography.ui(geometry.path(14)))
        .foregroundStyle(Paper.muted)
        .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(geometry.path(12))
    .background {
      Deckle(seed: 42, jitter: geometry.path(1.6), step: geometry.path(9))
        .fill(Paper.shade)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(Self.next.name) is waiting. Words like \(words).")
  }

  @ViewBuilder
  private var buttons: some View {
    Button("Keep reading", action: keepReading)
      .font(Typography.display(geometry.path(16)))
      .foregroundStyle(Paper.ink)
      .padding(.horizontal, geometry.path(16))
      .frame(height: geometry.path(46))
      .paperChip(Capsule(), rim: geometry.path(3))
      .buttonStyle(.plain)
    Button("Ask a grown-up", action: askAGrownUp)
      .font(Typography.display(geometry.path(16)))
      .foregroundStyle(Paper.onRed)
      .padding(.horizontal, geometry.path(18))
      .frame(height: geometry.path(46))
      .background(Paper.red, in: Capsule())
      .overlay(Capsule().strokeBorder(Paper.rim, lineWidth: geometry.path(3)))
      .buttonStyle(.plain)
  }
}
