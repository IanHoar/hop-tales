import ComposableArchitecture2
import Content
import Dependencies
import DesignSystem
import SwiftUI
import World

@Feature public struct Book {
  public init() {}

  public struct State: Identifiable {
    public var id = "book"
    public var progress = Content.Progress()
    public var friend: Friend

    public init(friend: Friend) {
      self.friend = friend
    }

    var basket: Basket { progress.baskets[friend] ?? Basket() }

    var storiesRead: [Story] {
      StoryLibrary.stories(at: friend.level).filter { story in
        (progress.completedSentences[story.id] ?? 0) >= story.sentences.count
      }
    }
  }

  public enum Action {
    case doneTapped
    case friendPicked(Friend)
  }

  @Dependency(ProgressStore.self) var progressStore

  public var body: some Feature {
    Update { state, action in
      switch action {
      case .doneTapped:
        break

      case let .friendPicked(friend):
        guard state.progress.journey.met.contains(friend) else { break }
        state.friend = friend
      }
    }
    .onMount { state in
      state.progress = progressStore.load()
    }
  }
}

public struct BookScreen: View {
  static let goldenSlots = 5

  let store: StoreOf<Book>

  public init(store: StoreOf<Book>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      SheetHeader(title: "Collection book") { store.send(.doneTapped) }
      HStack(alignment: .top, spacing: 0) {
        ScrollView {
          page
            .padding(22)
            .background {
              Deckle(seed: 19, jitter: 3, step: 14)
                .fill(Paper.paper)
                .shadow(color: Paper.shadow, radius: 8, y: 5)
            }
            .padding(.leading, 20)
            .padding(.bottom, 30)
        }
        tabs
          .padding(.top, 20)
      }
    }
    .background(Paper.page.ignoresSafeArea())
  }

  private var page: some View {
    let friend = store.friend
    let basket = store.state.basket
    return VStack(alignment: .leading, spacing: 18) {
      Text("\(friend.name)'s basket")
        .font(Typography.display(26))
        .foregroundStyle(Paper.ink)
        .accessibilityAddTraits(.isHeader)
      HStack(spacing: 12) {
        HStack(spacing: -14) {
          ForEach(0..<min(max(basket.total, 1), 4), id: \.self) { index in
            Sticker("collect-\(friend.treat.art)", height: 52)
              .rotationEffect(.degrees(Double(index * 14 - 20)))
              .opacity(basket.total == 0 ? 0.3 : 1)
          }
        }
        VStack(alignment: .leading, spacing: 0) {
          Text("\(basket.total)")
            .font(Typography.display(38))
            .foregroundStyle(Paper.ink)
            .monospacedDigit()
          Text("\(friend.treat.many) found")
            .font(Typography.ui(15, weight: .medium))
            .foregroundStyle(Paper.muted)
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("\(basket.total) \(friend.treat.many) found")
      section("Golden \(friend.treat.many)") {
        ForEach(0..<max(Self.goldenSlots, basket.golden), id: \.self) { index in
          slot(filled: index < basket.golden) {
            TreatStickerArt(friend: friend, isGolden: true)
          }
        }
      }
      section("Reading levels") {
        ForEach(Friend.allCases, id: \.self) { level in
          slot(filled: store.progress.journey.met.contains(level)) {
            Rosette(level: level.level)
          }
        }
      }
      if !store.state.storiesRead.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          Text("Stories read")
            .font(Typography.display(18))
            .foregroundStyle(Paper.ink)
          FlowStamps(titles: store.state.storiesRead.map(\.title))
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func section<Content: View>(
    _ title: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(Typography.display(18))
        .foregroundStyle(Paper.ink)
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 10)], spacing: 10) {
        content()
      }
    }
  }

  private func slot<Art: View>(filled: Bool, @ViewBuilder art: () -> Art) -> some View {
    ZStack {
      if filled {
        art()
      } else {
        RoundedRectangle(cornerRadius: 12)
          .strokeBorder(Paper.muted.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
      }
    }
    .frame(width: 52, height: 58)
  }

  private var tabs: some View {
    VStack(spacing: 10) {
      ForEach(Friend.allCases, id: \.self) { friend in
        let met = store.progress.journey.met.contains(friend)
        Button { store.send(.friendPicked(friend)) } label: {
          FriendSticker(friend, height: 38, isSilhouette: !met)
            .opacity(met ? 1 : 0.35)
            .frame(width: 56, height: 56)
            .background(
              friend == store.friend ? Paper.paper : Paper.shade,
              in: UnevenRoundedRectangle(bottomTrailingRadius: 14, topTrailingRadius: 14)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
          met ? "\(friend.name)'s page" : "A friend at reading level \(friend.level)"
        )
      }
    }
  }
}

struct TreatStickerArt: View {
  let friend: Friend
  var isGolden = false

  var body: some View {
    if isGolden, friend == .hare {
      Sticker("collect-carrot-gold", height: 44)
    } else {
      Sticker("collect-\(friend.treat.art)", height: 44)
        .colorMultiply(isGolden ? Color(hex: 0xF3C64A) : .white)
    }
  }
}

struct FlowStamps: View {
  let titles: [String]

  var body: some View {
    let columns = [GridItem(.adaptive(minimum: 130), spacing: 8)]
    LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
      ForEach(titles, id: \.self) { title in
        Text(title)
          .font(Typography.display(14))
          .foregroundStyle(Paper.ink)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(Paper.shade, in: RoundedRectangle(cornerRadius: 8))
          .rotationEffect(.degrees(title.count.isMultiple(of: 2) ? -1.5 : 1.5))
      }
    }
  }
}

#if DEBUG
struct BookPreview: View {
  var body: some View {
    BookScreen(store: store)
      .frame(width: Metrics.phone.reference.width, height: Metrics.phone.reference.height)
  }

  private var store: StoreOf<Book> {
    var basket = Basket()
    basket.total = 64
    basket.golden = 3
    let saved = Content.Progress(
      completedSentences: ["golden-hour": 6, "dash-and-frog": 6],
      journey: Journey(starting: .hare),
      baskets: [.hare: basket]
    )
    return withDependencies {
      $0[ProgressStore.self] = ProgressStore(load: { saved }, save: { _ in })
    } operation: {
      Store(initialState: Book.State(friend: .hare)) { Book() }
    }
  }
}

#Preview { BookPreview() }
#endif
