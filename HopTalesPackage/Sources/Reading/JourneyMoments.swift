import Content
import DesignSystem
import SwiftUI
import World

extension JourneyMoment {
  var waitingFriend: Friend? {
    switch self {
    case let .bigStoryReady(friend), let .notYet(friend): friend
    case .tally, .newFriend, .treat, .basketFull: nil
    }
  }
}

struct TallyCard: View {
  let steps: Double
  let total: Double
  let goal: Double
  let bigWords: Int
  let next: Friend
  var treat: CollectedTreat?
  var trail = 0
  let geometry: ReadingGeometry

  var body: some View {
    VStack(spacing: geometry.path(10)) {
      if let treat {
        HStack(spacing: geometry.path(6)) {
          TreatSticker(friend: treat.friend, isGolden: treat.isGolden, height: geometry.path(26))
          Text(treatLine(treat))
            .font(Typography.display(geometry.path(17)))
            .foregroundStyle(Paper.ink)
        }
      }
      if bigWords > 0 {
        HStack(spacing: geometry.path(6)) {
          Sticker("collect-star", height: geometry.path(22))
          Text(bigWords == 1 ? "A big word read!" : "\(bigWords) big words read!")
            .font(Typography.display(geometry.path(17)))
            .foregroundStyle(Paper.ink)
        }
      }
      HStack(spacing: geometry.path(12)) {
        FriendSticker(next, height: geometry.path(46), isSilhouette: total < goal)
          .opacity(total < goal ? 0.55 : 1)
        VStack(alignment: .leading, spacing: geometry.path(6)) {
          Text("The path to \(next.name)")
            .font(Typography.display(geometry.path(16)))
            .foregroundStyle(Paper.ink)
          PathRibbon(fill: goal > 0 ? total / goal : 1, geometry: geometry)
          Text("+\(Int(steps.rounded())) steps · \(Int(total)) of \(Int(goal))")
            .font(Typography.ui(geometry.path(13), weight: .medium))
            .foregroundStyle(Paper.muted)
            .monospacedDigit()
        }
      }
    }
    .padding(geometry.path(16))
    .frame(maxWidth: geometry.path(320))
    .background {
      Deckle(seed: 21, jitter: geometry.path(2.4), step: geometry.path(10))
        .fill(Paper.paper)
        .shadow(color: Paper.shadow, radius: geometry.path(8), y: geometry.path(5))
    }
    .rotationEffect(.degrees(-1.5))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      "\(Int(steps.rounded())) steps. \(Int(total)) of \(Int(goal)) on the path to \(next.name)."
    )
  }
}

extension TallyCard {
  func treatLine(_ treat: CollectedTreat) -> String {
    if treat.isTrail {
      let treats = treat.friend.treat.many.capitalized
      return "\(treats) for \(treat.friend.name) · \(trail) of \(Levels.trailGoal)"
    }
    return treat.isGolden
      ? "A golden \(treat.friend.treat.one)! That counts \(treat.worth)."
      : "You found a \(treat.friend.treat.one)!"
  }
}

struct TreatSticker: View {
  static let gold = Color(hex: 0xF3C64A)

  let friend: Friend
  var isGolden = false
  let height: CGFloat

  var body: some View {
    if isGolden, friend == .hare {
      Sticker("collect-carrot-gold", height: height)
    } else {
      Sticker("collect-\(friend.treat.art)", height: height)
        .colorMultiply(isGolden ? Self.gold : .white)
    }
  }
}

struct PathRibbon: View {
  let fill: Double
  let geometry: ReadingGeometry

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .leading) {
        Deckle(seed: 8, jitter: geometry.path(1.2), step: geometry.path(6))
          .fill(Paper.muted.opacity(0.22))
        Deckle(seed: 9, jitter: geometry.path(1.2), step: geometry.path(6))
          .fill(Paper.wash)
          .frame(width: max(proxy.size.width * min(max(fill, 0), 1), 0))
      }
    }
    .frame(width: geometry.path(180), height: geometry.path(12))
  }
}

struct CalloutCard: View {
  let moment: JourneyMoment
  let geometry: ReadingGeometry
  let primary: () -> Void
  let dismiss: () -> Void
  @State private var opened = false

  private var waitsForOpening: Bool {
    if case .basketFull = moment { return !opened }
    return false
  }

  var body: some View {
    VStack(spacing: geometry.path(12)) {
      art
      Text(title)
        .font(Typography.display(geometry.path(22)))
        .foregroundStyle(Paper.ink)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
      Text(detail)
        .font(Typography.ui(geometry.path(15), weight: .medium))
        .foregroundStyle(Paper.ink.opacity(0.85))
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
      HStack(spacing: geometry.path(10)) {
        if waitsForOpening {
          Text("Tap the present to open it")
            .font(Typography.ui(geometry.path(14), weight: .semibold))
            .foregroundStyle(Paper.muted)
        } else if let secondary {
          Button(secondary, action: dismiss)
            .font(Typography.display(geometry.path(16)))
            .foregroundStyle(Paper.ink)
            .padding(.horizontal, geometry.path(16))
            .frame(height: geometry.path(46))
            .paperChip(Capsule(), rim: geometry.path(3))
            .buttonStyle(.plain)
        }
        let leads = moment.story != nil || moment.unlockedItem != nil
        if !waitsForOpening {
          primaryButton(action: leads ? primary : dismiss)
        }
      }
      .padding(.top, geometry.path(4))
    }
    .padding(geometry.path(20))
    .frame(maxWidth: geometry.path(340))
    .background {
      Deckle(seed: 33, jitter: geometry.path(2.6), step: geometry.path(10))
        .fill(Paper.paper)
        .shadow(color: Paper.shadow, radius: geometry.path(10), y: geometry.path(6))
    }
    .rotationEffect(.degrees(-1))
    .accessibilityElement(children: .contain)
  }

  private func primaryButton(action: @escaping () -> Void) -> some View {
    Button(primaryTitle, action: action)
      .font(Typography.display(geometry.path(16)))
      .foregroundStyle(Paper.onRed)
      .padding(.horizontal, geometry.path(18))
      .frame(height: geometry.path(46))
      .background(Paper.red, in: Capsule())
      .overlay(Capsule().strokeBorder(Paper.rim, lineWidth: geometry.path(3)))
      .buttonStyle(.plain)
  }

  @ViewBuilder
  private var art: some View {
    switch moment {
    case let .bigStoryReady(friend), let .notYet(friend):
      Postcard(friend: friend, geometry: geometry)
    case let .newFriend(friend, _):
      HStack(alignment: .bottom, spacing: geometry.path(6)) {
        FriendSticker(Friend.at(level: friend.level - 1), height: geometry.path(62))
        ZStack {
          Sticker("collect-rosette", height: geometry.path(64))
          Text("\(friend.level)")
            .font(Typography.display(geometry.path(20)))
            .foregroundStyle(Paper.ink)
            .offset(y: -geometry.path(6))
        }
        FriendSticker(friend, height: geometry.path(78))
      }
    case let .basketFull(friend, _):
      PresentReveal(friend: friend, item: moment.unlockedItem, geometry: geometry, opened: $opened)
    case .tally, .treat:
      EmptyView()
    }
  }

  private var title: String {
    switch moment {
    case let .bigStoryReady(friend): "\(friend.name) has a bigger story!"
    case let .notYet(friend): "\(friend.name) will wait for you at \(friend.place)."
    case let .newFriend(friend, _): "Reading level \(friend.level)!"
    case .basketFull: "A full basket!"
    case .tally, .treat: ""
    }
  }

  private var detail: String {
    switch moment {
    case let .bigStoryReady(friend):
      "The path is full. Read \(friend.name)'s story to go to \(friend.place) together."
    case .notYet:
      "The path stays full. Try the big story again whenever you like."
    case let .newFriend(friend, via):
      "\(friend.name) is your new friend. \(friend.name) gave you \(friend.gift)."
        + (via == .trail ? " You found all the \(friend.treat.many)!" : "")
    case let .basketFull(friend, _):
      opened
        ? "It's " + (moment.unlockedItem.map { "a \($0.name.lowercased())" } ?? "a present")
          + " for \(friend.name)!"
        : "You filled \(friend.name)'s basket of \(friend.treat.many). There's a present inside!"
    case .tally, .treat:
      ""
    }
  }

  private var primaryTitle: String {
    switch moment {
    case .bigStoryReady: "Try the big story"
    case .notYet: "OK"
    case let .newFriend(friend, _): "Go to \(friend.place)"
    case .basketFull: "Try it on"
    case .tally, .treat: ""
    }
  }

  private var secondary: String? {
    switch moment {
    case .bigStoryReady: "Not yet"
    case .newFriend, .basketFull: "Later"
    case .notYet, .tally, .treat: nil
    }
  }
}

struct PresentReveal: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let friend: Friend
  let item: WardrobeItem?
  let geometry: ReadingGeometry
  @Binding var opened: Bool

  var body: some View {
    Button {
      withAnimation(reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.4)) { opened = true }
    } label: {
      ZStack {
        if opened {
          Sticker("collect-present-open", height: geometry.path(96))
            .offset(x: -geometry.path(40))
          if let item {
            Sticker("wear-\(friend.rawValue)-\(item.id)", height: geometry.path(78))
              .offset(x: geometry.path(56), y: -geometry.path(24))
              .transition(.scale(scale: 0.2, anchor: .bottomLeading).combined(with: .opacity))
          }
        } else {
          Sticker("collect-present", height: geometry.path(110))
            .transition(.scale(scale: 1.1).combined(with: .opacity))
        }
      }
      .frame(height: geometry.path(120))
    }
    .buttonStyle(.plain)
    .disabled(opened)
    .accessibilityLabel(opened ? (item?.name ?? "A present") : "A present. Double tap to open it.")
  }
}

struct Postcard: View {
  let friend: Friend
  let geometry: ReadingGeometry

  var body: some View {
    Group {
      if friend == .hare {
        Image(
          uiImage: MeadowPostcard.image(mood: Mood(), size: CGSize(width: 300, height: 128))
        )
        .resizable()
      } else {
        Sticker(Sticker.postcard(friend), height: geometry.path(128))
      }
    }
    .frame(width: geometry.path(300), height: geometry.path(128))
    .clipShape(RoundedRectangle(cornerRadius: geometry.path(10), style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: geometry.path(10), style: .continuous)
        .strokeBorder(Paper.rim, lineWidth: geometry.path(4))
    )
    .rotationEffect(.degrees(1.5))
  }
}

struct PaperConfetti: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var fallen = false
  let size: CGSize

  private static let colours: [Color] = [
    Paper.red, Paper.wash, Paper.sage, Color(hex: 0x8FB7D9), Color(hex: 0xE8A7B8)
  ]

  var body: some View {
    ZStack {
      ForEach(0..<36, id: \.self) { index in
        let x = CGFloat((index * 37) % 100) / 100 * size.width
        RoundedRectangle(cornerRadius: 1.5)
          .fill(Self.colours[index % Self.colours.count])
          .frame(width: 7, height: 11)
          .rotationEffect(.degrees(fallen ? Double(index * 47) : 0))
          .position(
            x: x + (fallen ? CGFloat(index % 7 - 3) * 14 : 0),
            y: fallen ? size.height * (0.35 + CGFloat(index % 9) * 0.06) : -20
          )
          .opacity(fallen ? 0 : 1)
      }
    }
    .frame(width: size.width, height: size.height)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
    .onAppear {
      guard !reduceMotion else { return }
      withAnimation(.easeIn(duration: 2.2)) { fallen = true }
    }
  }
}
