import ComposableArchitecture2
import DesignSystem
import SwiftUI
import World

@Feature public struct Intro {
  public init() {}

  public struct State: Equatable {
    public init() {}
  }

  public enum Action {
    case finished
    case skipTapped
    case started(reduceMotion: Bool)
  }

  public var body: some Feature {
    Update { _, action in
      switch action {
      case .finished:
        break
      case .skipTapped:
        store.addTask { try store.send(.finished) }
      case let .started(reduceMotion):
        let delay = reduceMotion ? IntroTimeline.reducedRoute : IntroTimeline.route
        store.addTask {
          try await Task.sleep(for: .seconds(delay))
          try store.send(.finished)
        }
      }
    }
  }
}

public struct IntroScreen: View {
  let store: StoreOf<Intro>
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  public init(store: StoreOf<Intro>) {
    self.store = store
  }

  public var body: some View {
    IntroView()
      .overlay(alignment: .top) {
        if !reduceMotion {
          IntroTitle()
        }
      }
      .contentShape(Rectangle())
      .onTapGesture { store.send(.skipTapped) }
      .task { store.send(.started(reduceMotion: reduceMotion)) }
      .accessibilityElement()
      .accessibilityLabel("Hop Tales")
      .accessibilityAddTraits(.isHeader)
  }
}

struct IntroTitle: View {
  @State private var shown = false
  @State private var gone = false

  var body: some View {
    GeometryReader { proxy in
      let k = min(1.6, MeadowLayout(size: proxy.size).k)
      VStack(spacing: 10 * k) {
        PaperLabel(seed: 28) {
          Text("Hop Tales")
            .font(Typography.display(46 * k))
            .foregroundStyle(Paper.ink)
            .padding(.horizontal, 28 * k)
            .padding(.top, 12 * k)
            .padding(.bottom, 16 * k)
        }
        .rotationEffect(.degrees(-2))
        Text("a read-aloud adventure")
          .font(Typography.word(17 * min(1.5, k)))
          .foregroundStyle(Paper.ink.opacity(0.85))
      }
      .frame(maxWidth: .infinity)
      .padding(.top, proxy.size.height * 0.14)
      .opacity(shown && !gone ? 1 : 0)
      .offset(y: gone ? -24 : shown ? 0 : 10)
    }
    .ignoresSafeArea()
    .task {
      try? await Task.sleep(for: .seconds(IntroTimeline.titleIn))
      withAnimation(.easeInOut(duration: 0.6)) { shown = true }
      try? await Task.sleep(for: .seconds(IntroTimeline.titleOut - IntroTimeline.titleIn))
      let fade = IntroTimeline.route - IntroTimeline.titleOut
      withAnimation(.easeInOut(duration: fade)) { gone = true }
    }
  }
}

#Preview {
  IntroScreen(store: Store(initialState: Intro.State()) { Intro() })
}
