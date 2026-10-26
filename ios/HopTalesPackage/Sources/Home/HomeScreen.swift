import ComposableArchitecture
import Content
import Dependencies
import DesignSystem
import GrownUps
import SwiftUI
import World

extension EnvironmentValues {
  @Entry public var arrivesFromOnboarding = false
}

@Feature public struct Home {
  public init() {}

  public struct State {
    public var childName: String?
    var progress = Content.Progress()
    var hour: Int?
    public var isPlus = false
    public var locksStories = Plus.locksStories
    public var locked: LockedStory.State?
    public var grownUp: GrownUpPaywall.State?

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
      standings
        .filter { !isLocked($0.story) }
        .keepGoing(startingAt: progress.journey.activeFriend.startingStoryID)
    }

    public var lockedLevels: [Friend] {
      Plus.lockedLevels(
        above: progress.journey.activeFriend.level, isPlus: isPlus, locksStories: locksStories
      )
    }

    public func isLocked(_ story: Story) -> Bool {
      Plus.isLocked(story, isPlus: isPlus, locksStories: locksStories)
    }

    public mutating func showLocked(_ story: Story) {
      locked = LockedStory.State(standing: StoryStanding(story: story, progress: progress))
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
    case grownUp(GrownUpPaywall.Action)
    case journeyTapped
    case locked(LockedStory.Action)
    case lockedLevelTapped(Friend)
    case plusChanged(Bool)
    case wardrobeTapped
    case storyTapped(Story)
  }

  @Dependency(GateSeed.self) var gateSeed
  @Dependency(ProgressStore.self) var progressStore
  @Dependency(PurchasesClient.self) var purchases

  public var body: some Feature {
    Update { state, action in
      switch action {
      case .locked(.closeTapped):
        state.locked = nil
      case .lockedLevelTapped:
        state.grownUp = GrownUpPaywall.State(seed: gateSeed.draw())
      case .grownUp(.paywall(.subscribed)), .locked(.grownUp(.paywall(.subscribed))),
        .plusChanged(true):
        state.isPlus = true
        state.grownUp = nil
        state.locked = nil
      case .plusChanged(false):
        state.isPlus = false
      case .grownUp(.gate(.closeTapped)), .grownUp(.paywall(.closeTapped)):
        state.grownUp = nil
      case .bookTapped, .friendsTapped, .grownUp, .grownUpsTapped, .journeyTapped, .locked,
        .storyTapped, .wardrobeTapped:
        break
      }
    }
    .ifLet(\.locked) {
      LockedStory()
    }
    .ifLet(\.grownUp) {
      GrownUpPaywall()
    }
    .onMount { state in
      state.progress = progressStore.load()
      if state.hour == nil {
        state.hour = Calendar.current.component(.hour, from: Date())
      }
      guard state.locksStories else { return }
      let wasPlus = state.isPlus
      store.addTask {
        var current = wasPlus
        for await isPlus in purchases.isPlus() where isPlus != current {
          current = isPlus
          try store.send(.plusChanged(isPlus))
        }
      }
    }
  }
}

public struct HomeScreen: View {
  @Bindable var store: StoreOf<Home>
  @Environment(\.colorScheme) private var colorScheme
  @State private var sheetTop: CGFloat = 0
  @State private var scrolled: CGFloat = 0
  @State private var arrived = false
  @Environment(\.arrivesFromOnboarding) private var arrivesFromOnboarding
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.simulatedFold) private var simulatedFold

  public init(store: StoreOf<Home>) {
    self.store = store
  }

  static let sheetTop: CGFloat = 0.51
  static let lowHorizon: CGFloat = 0.8
  static let topClearance: CGFloat = 20
  static let feetAboveSheet: CGFloat = 100
  static let landScale: CGFloat = 0.6
  static let friendHeight: CGFloat = 170
  static let columnWidth: CGFloat = 560
  static let wideLayout: CGFloat = 760
  static let tornEdge: CGFloat = 6

  public var body: some View {
    GeometryReader { proxy in
      let screen = proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
      let mood = Mood(sky: colorScheme == .dark ? .night : .day)
      let fold = proxy.fold(or: simulatedFold).flatMap { $0.runsAcross ? nil : $0 }
      let room = fold?.room(in: proxy.size)
      let standsAside = fold != nil || proxy.size.width > Self.wideLayout
      let column = min(Self.columnWidth, (room?.width ?? .infinity) - 32)
      let landscape = proxy.size.width > proxy.size.height
      let horizon = standsAside && landscape ? Self.lowHorizon : Self.sheetTop
      let framing = MeadowFraming.path(
        scale: Self.landScale * min(max(proxy.size.width / 390, 1), 1.3),
        centre: screen * horizon - Self.feetAboveSheet - 20
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
        HomeGround(
          world: store.progress.journey.activeFriend,
          mood: mood,
          tileWidth: land.tileSize(of: .near).width
        )
        .frame(height: max(0, screen - groundTop))
        .frame(maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea()
        if standsAside {
          friend
            .position(
              x: fold?.stage(in: proxy.size).midX ?? (proxy.size.width - Self.columnWidth) / 4,
              y: screen * horizon - Self.feetAboveSheet - Self.friendHeight / 2
            )
            .frame(width: proxy.size.width, height: screen)
            .ignoresSafeArea()
        }
        ScrollView {
          VStack(spacing: 0) {
            Color.clear
              .frame(height: sheetTop)
            sheet(bottomInset: proxy.safeAreaInsets.bottom)
              .animation(.spring(duration: 0.7, bounce: 0.12)) { content in
                content.offset(y: shown ? 0 : 160)
              }
          }
          .frame(maxWidth: column)
          .frame(maxWidth: .infinity)
          .frame(minHeight: proxy.size.height, alignment: .top)
          .background(alignment: .top) {
            VStack(spacing: 0) {
              topBar
                .padding(.top, max(8, Self.topClearance - proxy.safeAreaInsets.top))
                .animation(.spring(duration: 0.55, bounce: 0.35).delay(0.45)) { content in
                  content
                    .offset(y: shown ? 0 : -40)
                    .opacity(shown ? 1 : 0)
                }
              Spacer(minLength: 0)
                .frame(height: max(0, screen * Self.sheetTop - proxy.safeAreaInsets.top - 330))
              friendOnThePath(standsAside: standsAside)
            }
            .frame(maxWidth: column)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { sheetTop = $0 }
            .offset(y: scrolled)
          }
          .padding(.leading, room?.minX ?? 0)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
          geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
          scrolled = offset
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
      }
    }
    .navigationBarHidden(true)
    .onAppear { arrived = true }
    .sheet(item: $store.scope(\.locked)) { locked in
      LockedStoryScreen(store: locked)
    }
    .sheet(item: $store.scope(\.grownUp)) { grownUp in
      GrownUpPaywallScreen(store: grownUp)
    }
  }

  private var shown: Bool { arrived || !arrivesFromOnboarding || reduceMotion }

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
    .animation(.spring(duration: 0.5, bounce: 0.45).delay(0.25)) { content in
      content
        .scaleEffect(shown ? 1 : 0.4, anchor: .bottom)
        .opacity(shown ? 1 : 0)
    }
  }

  private func friendOnThePath(standsAside: Bool) -> some View {
    let journey = store.progress.journey
    return VStack(spacing: 14) {
      friend
        .opacity(standsAside ? 0 : 1)
        .accessibilityHidden(standsAside)
      LevelChip(journey: journey) { store.send(.journeyTapped) }
        .padding(.horizontal, 28)
        .animation(.easeOut(duration: 0.4).delay(0.35)) { content in
          content.opacity(shown ? 1 : 0)
        }
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
          Sticker(
            "wear-\(store.progress.journey.activeFriend.rawValue)-\(item.id)",
            fitting: CGSize(width: 52, height: 44)
          )
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
        StoryRow(standing: standing, isLocked: store.state.isLocked(standing.story)) {
          store.send(.storyTapped(standing.story))
        }
      }
      if !store.lockedLevels.isEmpty {
        Text("Next levels")
          .font(Typography.display(20))
          .foregroundStyle(Paper.ink)
          .padding(.top, 6)
          .accessibilityAddTraits(.isHeader)
        ForEach(store.lockedLevels, id: \.self) { friend in
          LockedLevelRow(friend: friend) { store.send(.lockedLevelTapped(friend)) }
        }
      }
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

#Preview {
  NavigationStack {
    HomeScreen(store: Store(initialState: Home.State(childName: "Wren")) { Home() })
  }
}
