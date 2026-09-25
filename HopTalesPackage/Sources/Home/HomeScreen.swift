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

  public var body: some View {
    GeometryReader { proxy in
      let screen = proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
      ZStack(alignment: .top) {
        MeadowBackdrop(progress: 900, mood: Mood(sky: colorScheme == .dark ? .night : .day))
        ScrollView {
          VStack(spacing: 0) {
            topBar
              .padding(.top, 8)
            HStack {
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
              Spacer(minLength: 0)
            }
            .padding(.top, 22)
            .padding(.horizontal, 6)
            Spacer(minLength: 0)
              .frame(height: max(0, screen * Self.sheetTop - proxy.safeAreaInsets.top - 124))
            sheet(bottomInset: proxy.safeAreaInsets.bottom)
          }
          .frame(maxWidth: 560)
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
    HStack(spacing: 10) {
      AppMark(size: 40)
      Text("Hop Tales")
        .font(Typography.display(24))
        .foregroundStyle(Paper.ink)
        .accessibilityAddTraits(.isHeader)
      Spacer(minLength: 8)
      HStack(spacing: 6) {
        StarBadge(size: 19)
        Text("\(store.progress.stars)")
          .font(Typography.display(17))
          .foregroundStyle(Paper.ink)
          .monospacedDigit()
      }
      .padding(.horizontal, 13)
      .frame(height: 46)
      .paperChip(Capsule())
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("\(store.progress.stars) stars")
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

  private func sheet(bottomInset: CGFloat) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      if let keepGoing = store.keepGoing {
        KeepGoingCard(standing: keepGoing) { store.send(.storyTapped(keepGoing.story)) }
      }
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
