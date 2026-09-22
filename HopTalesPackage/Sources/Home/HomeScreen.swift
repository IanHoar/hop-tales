import ComposableArchitecture2
import Content
import DesignSystem
import SwiftUI

@Feature public struct Home {
  public init() {}

  public struct State {
    public var childName: String?
    var progress = Content.Progress()
    var stories = StoryLibrary.all

    public init(childName: String? = nil) {
      self.childName = childName
    }

    var standings: [StoryStanding] {
      stories.map { StoryStanding(story: $0, progress: progress) }
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

  public var body: some Feature {
    Update { _, action in
      switch action {
      case .grownUpsTapped, .playOnTVTapped, .storyTapped:
        break
      }
    }
  }
}

public struct HomeScreen: View {
  let store: StoreOf<Home>

  public init(store: StoreOf<Home>) {
    self.store = store
  }

  public var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        header
          .padding(.top, 8)
        greeting
          .padding(.top, 28)
        if let keepGoing = store.standings.keepGoing {
          KeepGoingCard(standing: keepGoing) { store.send(.storyTapped(keepGoing.story)) }
            .padding(.top, 22)
        }
        Text("ALL STORIES")
          .font(Typography.caps(11))
          .tracking(1.76)
          .foregroundStyle(Palette.muted)
          .padding(.top, 26)
          .padding(.bottom, 12)
        VStack(spacing: 12) {
          ForEach(store.standings) { standing in
            StoryRow(standing: standing) { store.send(.storyTapped(standing.story)) }
          }
        }
        bottomBar
          .padding(.top, 26)
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 24)
    }
    .background(Palette.cream)
    .navigationBarHidden(true)
  }

  private var header: some View {
    HStack {
      HStack(spacing: 9) {
        BallMark()
          .frame(width: 26, height: 26)
        Text("Hop Tales")
          .font(Typography.ui(25))
          .foregroundStyle(Palette.ink)
      }
      Spacer()
      HStack(spacing: 6) {
        Star()
          .fill(Palette.amber)
          .frame(width: 17, height: 17)
        Text("\(store.progress.stars)")
          .font(Typography.ui(16))
          .foregroundStyle(Palette.starText)
      }
      .padding(.horizontal, 15)
      .frame(height: 44)
      .background(Palette.creamDeep, in: .capsule)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("\(store.progress.stars) stars")
    }
    .padding(.horizontal, 4)
  }

  private var greeting: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(store.greeting)
        .font(Typography.ui(30))
        .foregroundStyle(Palette.ink)
      Text("Ready for the next one?")
        .font(Typography.ui(17))
        .foregroundStyle(Palette.muted)
    }
    .padding(.horizontal, 4)
  }

  private var bottomBar: some View {
    HStack(spacing: 12) {
      Button { store.send(.playOnTVTapped) } label: {
        Label("Play on the TV", systemImage: "tv")
          .font(Typography.ui(16))
          .foregroundStyle(Palette.cream)
          .frame(maxWidth: .infinity)
          .frame(height: 58)
          .background(Palette.ink, in: .capsule)
      }
      Button { store.send(.grownUpsTapped) } label: {
        Image(systemName: "gearshape")
          .font(.system(size: 22, weight: .medium))
          .foregroundStyle(Palette.chipText)
          .frame(width: 58, height: 58)
          .background(Palette.surfaceMuted, in: .circle)
      }
      .accessibilityLabel("Grown-ups")
    }
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
