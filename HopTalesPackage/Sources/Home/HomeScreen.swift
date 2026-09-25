import ComposableArchitecture2
import Content
import Dependencies
import DesignSystem
import SwiftUI
import World

@Feature public struct Home {
  public init() {}

  public struct State {
    public var childName: String?
    var progress = Content.Progress()
    var hour: Int?

    public init(childName: String? = nil) {
      self.childName = childName
    }

    var stories: [Story] {
      let level = progress.journey.activeFriend.level
      return StoryLibrary.stories(at: level)
        + (1..<level).reversed().flatMap(StoryLibrary.stories(at:))
    }

    var standings: [StoryStanding] {
      stories.map { StoryStanding(story: $0, progress: progress) }
    }

    public mutating func apply(_ profile: Profile) {
      childName = profile.childName.isEmpty ? nil : profile.childName
    }

    public mutating func apply(_ progress: Content.Progress) {
      self.progress = progress
    }

    var keepGoing: StoryStanding? {
      standings.keepGoing(startingAt: progress.journey.activeFriend.startingStoryID)
    }

    var greeting: String {
      let time = switch hour ?? 9 {
      case 4..<12: "Good morning"
      case 12..<17: "Good afternoon"
      default: "Good evening"
      }
      guard let childName, !childName.isEmpty else { return "\(time)!" }
      return "\(time), \(childName)!"
    }
  }

  public enum Action {
    case grownUpsTapped
    case bookTapped
    case friendsTapped
    case journeyTapped
    case wardrobeTapped
    case playOnTVTapped
    case storyTapped(Story)
  }

  @Dependency(ProgressStore.self) var progressStore

  public var body: some Feature {
    Update { _, action in
      switch action {
      case .bookTapped, .friendsTapped, .grownUpsTapped, .journeyTapped, .playOnTVTapped,
        .storyTapped, .wardrobeTapped:
        break
      }
    }
    .onMount { state in
      state.progress = progressStore.load()
      if state.hour == nil {
        state.hour = Calendar.current.component(.hour, from: Date())
      }
    }
  }
}

public struct HomeScreen: View {
  let store: StoreOf<Home>
  @Environment(\.colorScheme) private var colorScheme

  public init(store: StoreOf<Home>) {
    self.store = store
  }

  static let sheetTop: CGFloat = 0.51
  static let feetAboveSheet: CGFloat = 100
  static let landScale: CGFloat = 0.6
  static let friendHeight: CGFloat = 170
  static let columnWidth: CGFloat = 560
  static let wideLayout: CGFloat = 760
  static let tornEdge: CGFloat = 6
  static func ground(_ style: WorldStyle) -> LinearGradient {
    LinearGradient(
      colors: [Color(hex: style.ground), Color(hex: 0xD9D6A6), Color(hex: 0xEDE6C8)],
      startPoint: .top,
      endPoint: .bottom
    )
  }

  public var body: some View {
    GeometryReader { proxy in
      let screen = proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
      let mood = Mood(sky: colorScheme == .dark ? .night : .day)
      let framing = MeadowFraming.path(
        scale: Self.landScale * min(max(proxy.size.width / 390, 1), 1.3),
        centre: screen * Self.sheetTop - Self.feetAboveSheet - 20
      )
      let land = MeadowLayout(
        size: CGSize(width: proxy.size.width, height: screen), framing: framing
      )
      let groundTop = land.top(of: .near) + land.tileSize(of: .near).height - Self.tornEdge
      ZStack(alignment: .top) {
        MeadowBackdrop(
          camera: MeadowCamera(at: 900), mood: mood, framing: framing,
          world: store.progress.journey.activeFriend
        )
        Self.ground(WorldStyle.of(store.progress.journey.activeFriend))
          .colorMultiply(Color(uiColor: mood.landTint))
          .frame(height: max(0, screen - groundTop))
          .frame(maxHeight: .infinity, alignment: .bottom)
          .ignoresSafeArea()
          .accessibilityHidden(true)
        if proxy.size.width > Self.wideLayout {
          friend
            .position(
              x: (proxy.size.width - Self.columnWidth) / 4,
              y: screen * Self.sheetTop - Self.feetAboveSheet - Self.friendHeight / 2
            )
            .frame(width: proxy.size.width, height: screen)
            .ignoresSafeArea()
        }
        ScrollView {
          VStack(spacing: 0) {
            topBar
              .padding(.top, 8)
            Spacer(minLength: 0)
              .frame(height: max(0, screen * Self.sheetTop - proxy.safeAreaInsets.top - 330))
            friendOnThePath(standsAside: proxy.size.width > Self.wideLayout)
            sheet(bottomInset: proxy.safeAreaInsets.bottom)
          }
          .frame(maxWidth: Self.columnWidth)
          .frame(maxWidth: .infinity)
          .frame(minHeight: proxy.size.height, alignment: .top)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
      }
    }
    .navigationBarHidden(true)
  }

  private var topBar: some View {
    HStack(alignment: .top) {
      PaperLabel(seed: 7) {
        Text(store.greeting)
          .font(Typography.display(21))
          .foregroundStyle(Paper.ink)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
          .padding(.horizontal, 18)
          .padding(.vertical, 9)
      }
      .rotationEffect(.degrees(-3))
      .accessibilityAddTraits(.isHeader)
      Spacer(minLength: 8)
      Button { store.send(.grownUpsTapped) } label: {
        Image(systemName: "gearshape")
          .font(.system(size: 19, weight: .semibold))
          .foregroundStyle(Paper.ink)
          .frame(width: 46, height: 46)
          .paperChip(Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Settings for grown-ups")
    }
    .padding(.horizontal, 20)
  }

  private var friend: some View {
    let friend = store.progress.journey.activeFriend
    return IdleFriend(
      friend,
      look: store.progress.outfit(for: friend).first?.id,
      height: Self.friendHeight
    )
    .shadow(color: Paper.shadow, radius: 6, y: 4)
  }

  private func friendOnThePath(standsAside: Bool) -> some View {
    let journey = store.progress.journey
    return VStack(spacing: 14) {
      friend
        .opacity(standsAside ? 0 : 1)
        .accessibilityHidden(standsAside)
      LevelChip(journey: journey) { store.send(.journeyTapped) }
        .padding(.horizontal, 28)
    }
    .padding(.bottom, 18)
  }

  private var stickerButtons: some View {
    HStack(spacing: 0) {
      StickerButton(title: "Friends") {
        FriendSticker(store.progress.journey.activeFriend, height: 52)
      } action: {
        store.send(.friendsTapped)
      }
      if let item = store.progress.newestItem(for: store.progress.journey.activeFriend) {
        StickerButton(title: "Wardrobe") {
          Sticker("wear-\(store.progress.journey.activeFriend.rawValue)-\(item.id)", height: 44)
        } action: {
          store.send(.wardrobeTapped)
        }
      }
      StickerButton(title: "Book") {
        Sticker("collect-basket", height: 50)
      } action: {
        store.send(.bookTapped)
      }
    }
    .padding(.vertical, 6)
  }

  private func sheet(bottomInset: CGFloat) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      if let keepGoing = store.keepGoing {
        KeepGoingCard(standing: keepGoing) { store.send(.storyTapped(keepGoing.story)) }
      }
      stickerButtons
      Text("More stories")
        .font(Typography.display(20))
        .foregroundStyle(Paper.ink)
        .padding(.top, 6)
        .accessibilityAddTraits(.isHeader)
      ForEach(store.standings.filter { $0.story.id != store.keepGoing?.story.id }) { standing in
        StoryRow(standing: standing) { store.send(.storyTapped(standing.story)) }
      }
      Button { store.send(.playOnTVTapped) } label: {
        Label("Play on the TV", systemImage: "tv")
          .font(Typography.ui(16))
          .foregroundStyle(Paper.ink)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .paperChip(Capsule())
      }
      .buttonStyle(.plain)
      .padding(.top, 10)
    }
    .padding(.horizontal, 24)
    .padding(.top, 26)
    .padding(.bottom, max(bottomInset, 16) + 18)
    .frame(maxHeight: .infinity, alignment: .top)
    .background {
      Deckle(seed: 21, jitter: 3, step: 16)
        .fill(Paper.paper)
        .padding(.bottom, -40)
        .shadow(color: Paper.shadow, radius: 10, y: -4)
    }
  }
}

struct StarBadge: View {
  let size: CGFloat

  var body: some View {
    Star()
      .fill(Paper.wash)
      .overlay(Star().stroke(Paper.washRing, lineWidth: max(1, size * 0.07)))
      .frame(width: size, height: size)
  }
}

#Preview {
  NavigationStack {
    HomeScreen(store: Store(initialState: Home.State(childName: "Wren")) { Home() })
  }
}

struct StickerButton<Art: View>: View {
  let title: String
  @ViewBuilder let art: () -> Art
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 6) {
        art()
          .frame(width: 84, height: 84)
          .background(Paper.rim.opacity(0.7), in: Circle())
          .overlay(Circle().strokeBorder(Paper.rim, lineWidth: 3))
          .shadow(color: Paper.shadow.opacity(0.6), radius: 4, y: 3)
        Text(title)
          .font(Typography.display(16))
          .foregroundStyle(Paper.ink)
      }
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
  }
}

struct LevelChip: View {
  let journey: Journey
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Rosette(level: journey.level)
          .frame(width: 40)
        VStack(alignment: .leading, spacing: 5) {
          Text(title)
            .font(Typography.display(16))
            .foregroundStyle(Paper.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
          if journey.nextFriend != nil {
            GeometryReader { proxy in
              ZStack(alignment: .leading) {
                Capsule().fill(Paper.muted.opacity(0.22))
                Capsule()
                  .fill(Paper.wash)
                  .frame(width: proxy.size.width * journey.fill)
              }
            }
            .frame(height: 8)
          }
        }
        Image(systemName: "map")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(Paper.ink)
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 10)
      .paperChip(RoundedRectangle(cornerRadius: 18, style: .continuous), rim: 3)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(title)
    .accessibilityHint("Opens your journey.")
  }

  private var title: String {
    guard let next = journey.nextFriend else {
      return "Level \(journey.level) · \(journey.activeFriend.name)"
    }
    return "Level \(journey.level) · \(Int(journey.steps)) of \(Int(journey.goal)) to \(next.name)"
  }
}
