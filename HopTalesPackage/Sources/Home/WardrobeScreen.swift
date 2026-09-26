import ComposableArchitecture2
import Content
import Dependencies
import DesignSystem
import SwiftUI
import World

@Feature public struct Wardrobe {
  public init() {}

  public struct State: Identifiable {
    public var id: Friend { friend }
    public var friend: Friend
    public var progress = Content.Progress()

    public init(friend: Friend) {
      self.friend = friend
    }

    var items: [WardrobeItem] { WardrobeLibrary.items(for: friend) }

    var newest: WardrobeItem? { progress.newestItem(for: friend) }

    var outfit: [WardrobeItem] { progress.outfit(for: friend) }

    func isWorn(_ item: WardrobeItem) -> Bool { outfit.contains(item) }

    func basket(for item: WardrobeItem) -> Int {
      WardrobeLibrary.items(for: friend).firstIndex(of: item) ?? 0
    }
  }

  public enum Action {
    case doneTapped
    case itemTapped(WardrobeItem)
    case justMeTapped
  }

  @Dependency(ProgressStore.self) var progressStore

  public var body: some Feature {
    Update { state, action in
      switch action {
      case .doneTapped:
        break

      case let .itemTapped(item):
        guard state.progress.isUnlocked(item, for: state.friend) else { break }
        if state.isWorn(item) {
          state.progress.takeOff(item.slot, from: state.friend)
        } else {
          state.progress.wear(item, on: state.friend)
        }
        save(state)

      case .justMeTapped:
        state.progress.undress(state.friend)
        save(state)
      }
    }
    .onMount { state in
      state.progress = progressStore.load()
    }
  }

  private func save(_ state: State) {
    var progress = progressStore.load()
    progress.outfits[state.friend] = state.progress.outfits[state.friend]
    progressStore.save(progress)
  }
}

public struct WardrobeScreen: View {
  static let tile: CGFloat = 82

  let store: StoreOf<Wardrobe>

  public init(store: StoreOf<Wardrobe>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      header
      ScrollView {
        VStack(spacing: 18) {
          DressedFriend(store.friend, wearing: store.outfit, height: 200)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background {
              Deckle(seed: 14, jitter: 3, step: 14)
                .fill(Paper.shade)
            }
            .animation(.spring(duration: 0.35, bounce: 0.3), value: store.outfit)
          grid
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
      }
    }
    .background(Paper.page.ignoresSafeArea())
  }

  private var header: some View {
    HStack {
      Text("\(store.friend.name)'s wardrobe")
        .font(Typography.display(24))
        .foregroundStyle(Paper.ink)
        .accessibilityAddTraits(.isHeader)
      Spacer()
      Button("Done") { store.send(.doneTapped) }
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

  private var grid: some View {
    LazyVGrid(
      columns: [GridItem(.adaptive(minimum: Self.tile, maximum: Self.tile + 20), spacing: 12)],
      spacing: 12
    ) {
      tile(isSelected: !store.items.contains(where: store.state.isWorn), isLocked: false) {
        store.send(.justMeTapped)
      } label: {
        Text("Just me")
          .font(Typography.display(15))
          .foregroundStyle(Paper.ink)
      }
      .accessibilityLabel("Just me, nothing on")
      ForEach(store.items) { item in
        let unlocked = store.progress.isUnlocked(item, for: store.friend)
        tile(isSelected: store.state.isWorn(item), isLocked: !unlocked) {
          store.send(.itemTapped(item))
        } label: {
          ZStack {
            Sticker(
              "wear-\(store.friend.rawValue)-\(item.id)",
              fitting: CGSize(width: Self.tile * 0.78, height: Self.tile * 0.62)
            )
              .saturation(unlocked ? 1 : 0)
              .opacity(unlocked ? 1 : 0.35)
            if unlocked, item == store.state.newest, !store.state.isWorn(item) {
              Text("new")
                .font(Typography.ui(11, weight: .semibold))
                .foregroundStyle(Paper.onRed)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Paper.red, in: Capsule())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(6)
            }
            if !unlocked {
              VStack(spacing: 2) {
                Image(systemName: "lock.fill")
                  .font(.system(size: 18, weight: .semibold))
                Text("Basket \(store.state.basket(for: item))")
                  .font(Typography.ui(11, weight: .semibold))
              }
              .foregroundStyle(Paper.ink.opacity(0.8))
            }
          }
        }
        .accessibilityLabel(unlocked ? item.name : "\(item.name), locked")
      }
    }
  }

  private func tile<Label: View>(
    isSelected: Bool,
    isLocked: Bool,
    action: @escaping () -> Void,
    @ViewBuilder label: () -> Label
  ) -> some View {
    Button(action: action) {
      label()
        .frame(width: Self.tile, height: Self.tile)
        .background(isLocked ? Paper.shade : Paper.paper, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .strokeBorder(isSelected ? Paper.red : Paper.rim, lineWidth: isSelected ? 4 : 2)
        )
        .shadow(color: Paper.shadow.opacity(0.5), radius: 3, y: 2)
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

#if DEBUG
struct WardrobePreview: View {
  var friend = Friend.bunny

  var body: some View {
    WardrobeScreen(store: store)
      .frame(width: Metrics.phone.reference.width, height: Metrics.phone.reference.height)
  }

  private var store: StoreOf<Wardrobe> {
    var basket = Basket()
    basket.filled = 3
    let worn = WardrobeLibrary.items(for: friend).dropFirst().first
    let saved = Content.Progress(
      journey: Journey(starting: .frog),
      baskets: [friend: basket],
      outfits: worn.map { [friend: [$0.slot: $0.id]] } ?? [:]
    )
    return withDependencies {
      $0[ProgressStore.self] = ProgressStore(load: { saved }, save: { _ in })
    } operation: {
      Store(initialState: Wardrobe.State(friend: friend)) { Wardrobe() }
    }
  }
}

#Preview("Bramble") { WardrobePreview() }
#Preview("Hare") { WardrobePreview(friend: .hare) }
#endif
