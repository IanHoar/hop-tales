import ComposableArchitecture2
import Content
import Dependencies
import DesignSystem
import SwiftUI
import World

@Feature public struct Friends {
  public init() {}

  public struct State: Identifiable {
    public var id = "friends"
    public var progress = Content.Progress()

    public init() {}

    var journey: Journey { progress.journey }
  }

  public enum Action {
    case doneTapped
    case friendTapped(Friend)
    case journeyTapped
  }

  @Dependency(ProgressStore.self) var progressStore

  public var body: some Feature {
    Update { state, action in
      switch action {
      case .doneTapped, .journeyTapped:
        break

      case let .friendTapped(friend):
        guard state.progress.journey.met.contains(friend) else { break }
        state.progress.journey.readWith(friend)
        var saved = progressStore.load()
        saved.journey = state.progress.journey
        progressStore.save(saved)
      }
    }
    .onMount { state in
      state.progress = progressStore.load()
    }
  }
}

public struct FriendsScreen: View {
  let store: StoreOf<Friends>

  public init(store: StoreOf<Friends>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      SheetHeader(title: "Friends", done: { store.send(.doneTapped) }, accessory: {
        Button { store.send(.journeyTapped) } label: {
          Image(systemName: "map")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Paper.ink)
            .frame(width: 40, height: 40)
            .paperChip(Circle(), rim: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Your journey")
      })
      ScrollView {
        let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible())]
        LazyVGrid(columns: columns, spacing: 14) {
          ForEach(Friend.allCases, id: \.self) { friend in
            FriendCard(friend: friend, progress: store.progress) {
              store.send(.friendTapped(friend))
            }
          }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
      }
    }
    .background(Paper.page.ignoresSafeArea())
  }
}

struct FriendCard: View {
  let friend: Friend
  let progress: Content.Progress
  let action: () -> Void

  private var journey: Journey { progress.journey }
  private var isMet: Bool { journey.met.contains(friend) }
  private var isReading: Bool { friend == journey.activeFriend }
  private var isNext: Bool { friend == journey.nextFriend }

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 6) {
        ZStack(alignment: .topTrailing) {
          Group {
            if isMet {
              DressedFriend(friend, wearing: progress.outfit(for: friend), height: 96)
            } else {
              FriendSticker(friend, height: 96, isSilhouette: !isNext)
                .opacity(isNext ? 1 : 0.35)
                .saturation(isNext ? 0.4 : 1)
            }
          }
          .frame(maxWidth: .infinity)
          .frame(height: 110)
          if let tag {
            Text(tag)
              .font(Typography.ui(12, weight: .semibold))
              .foregroundStyle(isReading ? Paper.onRed : Paper.ink)
              .padding(.horizontal, 8)
              .padding(.vertical, 3)
              .background(isReading ? Paper.red : Paper.wash, in: Capsule())
          }
        }
        Text(isMet || isNext ? friend.name : "?")
          .font(Typography.display(20))
          .foregroundStyle(Paper.ink)
        detail
      }
      .padding(14)
      .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
      .background(Paper.paper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .strokeBorder(isReading ? Paper.red : Paper.rim, lineWidth: isReading ? 4 : 3)
      )
      .shadow(color: Paper.shadow.opacity(0.5), radius: 4, y: 3)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
    .accessibilityAddTraits(isReading ? [.isButton, .isSelected] : .isButton)
  }

  private var tag: String? {
    if isReading { return "reading" }
    return isNext ? "next" : nil
  }

  @ViewBuilder
  private var detail: some View {
    if isMet {
      HStack(spacing: 6) {
        Rosette(level: friend.level)
          .scaleEffect(0.8)
          .frame(width: 30, height: 30)
        Text("Level \(friend.level)")
          .font(Typography.ui(14, weight: .semibold))
          .foregroundStyle(Paper.ink)
        Spacer(minLength: 4)
        Sticker("collect-\(friend.treat.art)", height: 20)
        Text("\(progress.baskets[friend]?.total ?? 0)")
          .font(Typography.ui(14, weight: .semibold))
          .foregroundStyle(Paper.ink)
          .monospacedDigit()
      }
    } else {
      Text(
        isNext
          ? "Level \(friend.level) · fill the path, then read the big story"
          : "Reading level \(friend.level)"
      )
        .font(Typography.ui(13, weight: .medium))
        .foregroundStyle(Paper.muted)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var label: String {
    if isReading { return "\(friend.name), level \(friend.level). Reading now." }
    if isMet { return "\(friend.name), level \(friend.level). Tap to read with \(friend.name)." }
    if isNext { return "\(friend.name) is next. Fill the path, then read the big story." }
    return "A friend at reading level \(friend.level)."
  }
}

struct SheetHeader<Accessory: View>: View {
  let title: String
  let done: () -> Void
  @ViewBuilder var accessory: () -> Accessory

  var body: some View {
    HStack(spacing: 12) {
      PaperLabel(seed: 11) {
        Text(title)
          .font(Typography.display(22))
          .foregroundStyle(Paper.ink)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
      }
      .rotationEffect(.degrees(-2))
      .accessibilityAddTraits(.isHeader)
      Spacer()
      accessory()
      Button("Done", action: done)
        .font(Typography.display(17))
        .foregroundStyle(Paper.ink)
        .padding(.horizontal, 16)
        .frame(height: 40)
        .paperChip(Capsule(), rim: 3)
        .buttonStyle(.plain)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
  }
}

extension SheetHeader where Accessory == EmptyView {
  init(title: String, done: @escaping () -> Void) {
    self.init(title: title, done: done) { EmptyView() }
  }
}

#if DEBUG
struct FriendsPreview: View {
  var body: some View {
    FriendsScreen(store: store)
      .frame(width: Metrics.phone.reference.width, height: Metrics.phone.reference.height)
  }

  private var store: StoreOf<Friends> {
    var journey = Journey(starting: .hare)
    journey.steps = 412
    var basket = Basket()
    basket.total = 64
    let saved = Content.Progress(journey: journey, baskets: [.hare: basket])
    return withDependencies {
      $0[ProgressStore.self] = ProgressStore(load: { saved }, save: { _ in })
    } operation: {
      Store(initialState: Friends.State()) { Friends() }
    }
  }
}

#Preview { FriendsPreview() }
#endif
