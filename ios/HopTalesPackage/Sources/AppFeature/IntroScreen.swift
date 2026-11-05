import ComposableArchitecture
import Dependencies
import DesignSystem
import SwiftUI
import World

public struct MotionPreference: Sendable {
  public var reducesMotion: @Sendable () -> Bool

  public init(reducesMotion: @escaping @Sendable () -> Bool) {
    self.reducesMotion = reducesMotion
  }
}

extension MotionPreference: DependencyKey {
  public static let liveValue = MotionPreference {
    MainActor.assumeIsolated { UIAccessibility.isReduceMotionEnabled }
  }
  public static let testValue = MotionPreference { false }
}

@Feature public struct Intro {
  public init() {}

  public struct State: Equatable {
    public init() {}
  }

  public enum Action {
    case skipTapped
  }

  @Dependency(\.continuousClock) var clock
  @Dependency(MotionPreference.self) var motion

  public var body: some Feature {
    Update { _, action in
      switch action {
      case .skipTapped:
        store.addTask { try store.dismiss() }
      }
    }
    .onMount { _ in
      let delay = motion.reducesMotion() ? IntroTimeline.reducedRoute : IntroTimeline.route
      store.addTask {
        try await clock.sleep(for: .seconds(delay))
        try store.dismiss()
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
      .accessibilityElement()
      .accessibilityLabel("Hop Tales")
      .accessibilityAddTraits(.isHeader)
  }
}

struct IntroTitle: View {
  @State private var shown: Bool
  @State private var gone = false

  init(shown: Bool = false) {
    _shown = State(initialValue: shown)
  }

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
    .environment(\.colorScheme, .light)
    .task {
      guard !shown else { return }
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
