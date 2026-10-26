import ComposableArchitecture
import Content
import Dependencies
import DesignSystem
import GrownUps
import SwiftUI

@Feature public struct LockedStory {
  public init() {}

  public struct State: Identifiable {
    public var standing: StoryStanding
    public var grownUp: GrownUpPaywall.State?

    public init(standing: StoryStanding) {
      self.standing = standing
    }

    public var id: String { standing.id }

    var standingLine: String? {
      let total = standing.story.sentences.count
      switch standing.standing {
      case .unread: return nil
      case let .inProgress(remaining): return "You read \(total - remaining) of \(total)"
      case .finished: return "You read all \(total)"
      }
    }
  }

  public enum Action {
    case askAGrownUpTapped
    case closeTapped
    case grownUp(GrownUpPaywall.Action)
  }

  @Dependency(GateSeed.self) var gateSeed

  public var body: some Feature {
    Update { state, action in
      switch action {
      case .askAGrownUpTapped:
        state.grownUp = GrownUpPaywall.State(seed: gateSeed.draw())
      case .grownUp(.gate(.closeTapped)), .grownUp(.paywall(.closeTapped)):
        state.grownUp = nil
      case .closeTapped, .grownUp:
        break
      }
    }
    .ifLet(\.grownUp) {
      GrownUpPaywall()
    }
  }
}

public struct LockedStoryScreen: View {
  let store: StoreOf<LockedStory>

  public init(store: StoreOf<LockedStory>) {
    self.store = store
  }

  public var body: some View {
    Group {
      if let grownUp = store.scope(\.grownUp) {
        GrownUpPaywallScreen(store: grownUp)
      } else {
        VStack(spacing: 0) {
          SheetHeader(title: "Hop Tales Plus") { store.send(.closeTapped) }
          ScrollView {
            card
            .padding(24)
            .frame(maxWidth: .infinity)
            .background {
              Deckle(seed: 23, jitter: 3, step: 14)
                .fill(Paper.paper)
                .shadow(color: Paper.shadow, radius: 8, y: 5)
            }
            .frame(maxWidth: 460)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 30)
          }
        }
        .background(Paper.page.ignoresSafeArea())
      }
    }
  }

  private var story: Story { store.standing.story }

  private var card: some View {
    VStack(spacing: 14) {
      StoryThumbnail(mood: story.mood, cornerRadius: 20)
        .frame(height: 190)
        .overlay {
          RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(Paper.rim, lineWidth: 4)
        }
        .overlay(alignment: .bottomTrailing) {
          PadlockSticker(size: 64)
            .offset(x: 12, y: 16)
        }
        .padding(.bottom, 10)
      VStack(spacing: 6) {
        Text(story.title)
          .font(Typography.display(28))
          .foregroundStyle(Paper.ink)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
        if let line = store.state.standingLine {
          Text(line)
            .font(Typography.ui(16, weight: .medium))
            .foregroundStyle(Paper.muted)
        }
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel(accessibilityTitle)
      .accessibilityAddTraits(.isHeader)
      Text("This story is part of Hop Tales Plus.")
        .font(Typography.ui(18))
        .foregroundStyle(Paper.ink)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
      Button("Ask a grown-up") { store.send(.askAGrownUpTapped) }
        .buttonStyle(.paper)
        .padding(.top, 6)
    }
  }

  private var accessibilityTitle: String {
    let title = "\(story.title). Locked."
    guard let line = store.state.standingLine else { return title }
    return "\(title) \(line)."
  }
}

#if DEBUG
struct LockedStoryPreview: View {
  var completed = 4

  var body: some View {
    LockedStoryScreen(store: Store(initialState: state) { LockedStory() })
      .frame(width: Metrics.phone.reference.width, height: Metrics.phone.reference.height)
  }

  private var state: LockedStory.State {
    let story = StoryLibrary.stories(at: Friend.hare.level)[1]
    let progress = Content.Progress(completedSentences: [story.id: completed])
    return LockedStory.State(standing: StoryStanding(story: story, progress: progress))
  }
}

#Preview("Locked story") { LockedStoryPreview() }
#Preview("Locked story, not started") { LockedStoryPreview(completed: 0) }
#endif
