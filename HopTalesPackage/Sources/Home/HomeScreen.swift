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
    public var startingStoryID = StoryLibrary.all[0].id
    var progress = Content.Progress()
    var stories = StoryLibrary.all

    public init(childName: String? = nil) {
      self.childName = childName
    }

    var standings: [StoryStanding] {
      stories.map { StoryStanding(story: $0, progress: progress) }
    }

    public mutating func apply(_ profile: Profile) {
      childName = profile.childName.isEmpty ? nil : profile.childName
      startingStoryID = profile.startingStoryID
    }

    var keepGoing: StoryStanding? {
      standings.keepGoing(startingAt: startingStoryID)
    }

    var greeting: String {
      guard let childName, !childName.isEmpty else { return "Hi there" }
      return "Hi, \(childName)"
    }
  }

  public enum Action {
    case grownUpsTapped
    case playOnTVTapped
    case storyTapped(Story)
  }

  @Dependency(ProgressStore.self) var progressStore

  public var body: some Feature {
    Update { _, action in
      switch action {
      case .grownUpsTapped, .playOnTVTapped, .storyTapped:
        break
      }
    }
    .onMount { state in
      state.progress = progressStore.load()
    }
  }
}

public struct HomeScreen: View {
  let store: StoreOf<Home>
  @Environment(\.colorScheme) private var colorScheme

  public init(store: StoreOf<Home>) {
    self.store = store
  }

  static let headerHeight: CGFloat = 236
  static let pageTop: CGFloat = 236

  public var body: some View {
    ScrollView {
      ZStack(alignment: .top) {
        header
        VStack(alignment: .leading, spacing: 0) {
          if let keepGoing = store.keepGoing {
            KeepGoingCard(standing: keepGoing) { store.send(.storyTapped(keepGoing.story)) }
              .padding(.top, 150)
          } else {
            Color.clear.frame(height: Self.pageTop)
          }
          Text("ALL STORIES")
            .font(Typography.display(15))
            .tracking(15 * 0.12)
            .foregroundStyle(Palette.ink)
            .padding(.top, 24)
            .padding(.bottom, 12)
            .padding(.horizontal, 4)
          VStack(spacing: 14) {
            ForEach(store.standings) { standing in
              StoryRow(standing: standing) { store.send(.storyTapped(standing.story)) }
            }
          }
          bottomBar
            .padding(.top, 26)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 28)
      }
      .background(alignment: .top) { page }
    }
    .background(Palette.page)
    .scrollBounceBehavior(.basedOnSize)
    .navigationBarHidden(true)
  }

  private var tone: WorldArt.Tone { colorScheme == .dark ? .dusk : .day }

  private var header: some View {
    ZStack(alignment: .topLeading) {
      GeometryReader { proxy in
        let width = proxy.size.width
        let scale = width / 390 * 0.62
        if let image = WorldPostcard.image(
          tone: tone,
          progress: 0,
          scale: scale,
          size: CGSize(width: width, height: Self.headerHeight),
          top: 60 * scale
        ) {
          Image(uiImage: image)
            .resizable()
            .frame(width: width, height: Self.headerHeight)
        }
      }
      .frame(height: Self.headerHeight)
      .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .top) {
          Wordmark()
          Spacer()
          CoinChip(count: store.progress.stars, height: 46)
        }
        Text(store.greeting + "!")
          .font(Typography.display(28))
          .foregroundStyle(Palette.labelOnWorld)
          .inkHalo(3)
          .padding(.leading, 6)
      }
      .padding(.horizontal, 14)
      .padding(.top, 6)
    }
  }

  private var page: some View {
    VStack(spacing: 0) {
      Color.clear.frame(height: Self.pageTop)
      Rectangle().fill(Palette.outline).frame(height: 4)
      Palette.page
    }
  }

  private var bottomBar: some View {
    HStack(spacing: 12) {
      Button { store.send(.playOnTVTapped) } label: {
        Label("Play on the TV", systemImage: "tv")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.ink(.secondary))
      Button { store.send(.grownUpsTapped) } label: { cog }
        .accessibilityLabel("Settings")
    }
  }

  private var cog: some View {
    Image(systemName: "gearshape.fill")
      .font(.system(size: 22, weight: .bold))
      .foregroundStyle(Palette.ink)
      .frame(width: 58, height: 58)
      .parchmentBevel(Circle(), drop: 5)
  }
}

struct Wordmark: View {
  var body: some View {
    Text("Hop Tales")
      .font(Typography.display(44))
      .foregroundStyle(Palette.red)
      .overlay {
        Text("Hop Tales")
          .font(Typography.display(44))
          .foregroundStyle(Palette.redLight)
          .mask {
            Text("Hop Tales")
              .font(Typography.display(44))
              .offset(x: 1, y: 2)
              .blendMode(.destinationOut)
          }
          .compositingGroup()
          .offset(x: -1, y: -2)
          .opacity(0.9)
      }
      .inkHalo(4.5)
      .accessibilityAddTraits(.isHeader)
  }
}

struct BallMark: View {
  var body: some View {
    GeometryReader { proxy in
      let size = min(proxy.size.width, proxy.size.height)
      Circle()
        .fill(
          RadialGradient(
            colors: [Palette.ballHi, Palette.ball, Palette.ballLo],
            center: UnitPoint(x: 0.35, y: 0.3),
            startRadius: 0,
            endRadius: size * 0.8
          )
        )
        .overlay(alignment: .topLeading) {
          Circle()
            .fill(Color(hex: 0xFFF1DC, opacity: 0.9))
            .frame(width: size * 0.25, height: size * 0.25)
            .offset(x: size * 0.22, y: size * 0.22)
        }
    }
  }
}

#Preview {
  NavigationStack {
    HomeScreen(store: Store(initialState: Home.State(childName: "Wren")) { Home() })
  }
}
