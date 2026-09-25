import ComposableArchitecture2
import Content
import Dependencies
import DesignSystem
import SwiftUI
import World

@Feature public struct JourneyMap {
  public init() {}

  public struct State: Identifiable {
    public var id = "journey"
    public var journey = Journey()

    public init() {}

    public enum Stop: Equatable {
      case met
      case reading
      case next(bigStoryWaiting: Bool)
      case later
    }

    public func stop(for friend: Friend) -> Stop {
      if friend == journey.activeFriend { return .reading }
      if journey.met.contains(friend) { return .met }
      if friend == journey.nextFriend { return .next(bigStoryWaiting: journey.isPathFull) }
      return .later
    }
  }

  public enum Action {
    case bigStoryTapped(Story)
    case doneTapped
    case friendTapped(Friend)
  }

  @Dependency(ProgressStore.self) var progressStore

  public var body: some Feature {
    Update { state, action in
      switch action {
      case .bigStoryTapped, .doneTapped:
        break

      case let .friendTapped(friend):
        guard state.journey.met.contains(friend) else { break }
        state.journey.readWith(friend)
        var progress = progressStore.load()
        progress.journey = state.journey
        progressStore.save(progress)
      }
    }
    .onMount { state in
      state.journey = progressStore.load().journey
    }
  }
}

public struct JourneyMapScreen: View {
  static let spacing: CGFloat = 150
  static let inset: CGFloat = 110

  let store: StoreOf<JourneyMap>

  public init(store: StoreOf<JourneyMap>) {
    self.store = store
  }

  public var body: some View {
    GeometryReader { proxy in
      let points = Self.points(width: proxy.size.width)
      ScrollView {
        ZStack(alignment: .topLeading) {
          TrailShape(points: points)
            .stroke(Paper.shade, style: StrokeStyle(lineWidth: 34, lineCap: .round))
          TrailShape(points: points)
            .stroke(
              Paper.muted.opacity(0.35),
              style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 12])
            )
          progressDot(points)
          ForEach(Friend.allCases, id: \.self) { friend in
            stopView(friend)
              .position(points[friend.level - 1])
          }
        }
        .frame(width: proxy.size.width, height: Self.height)
      }
      .defaultScrollAnchor(.bottom)
      .scrollIndicators(.hidden)
    }
    .background(Paper.page.ignoresSafeArea())
    .safeAreaInset(edge: .top) { header }
  }

  static var height: CGFloat {
    CGFloat(Friend.allCases.count - 1) * spacing + inset * 2
  }

  static func points(width: CGFloat) -> [CGPoint] {
    Friend.allCases.indices.map { index in
      CGPoint(
        x: width * (index.isMultiple(of: 2) ? 0.32 : 0.68),
        y: height - inset - CGFloat(index) * spacing
      )
    }
  }

  private var header: some View {
    HStack {
      Text("Your journey")
        .font(Typography.display(26))
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
    .padding(.vertical, 10)
    .background(Paper.page)
  }

  @ViewBuilder
  private func progressDot(_ points: [CGPoint]) -> some View {
    let level = store.journey.level
    if level < points.count {
      let from = points[level - 1]
      let to = points[level]
      let point = TrailShape.point(from: from, to: to, at: 0.2 + 0.6 * store.journey.fill)
      Circle()
        .fill(Paper.wash)
        .overlay(Circle().strokeBorder(Paper.washRing, lineWidth: 3))
        .frame(width: 22, height: 22)
        .position(point)
        .accessibilityHidden(true)
    }
  }

  @ViewBuilder
  private func stopView(_ friend: Friend) -> some View {
    let stop = store.state.stop(for: friend)
    let bigStory = StoryLibrary.bigStory(at: friend.level)
    Button {
      guard isTappable(stop) else { return }
      if case .next(true) = stop, let bigStory {
        store.send(.bigStoryTapped(bigStory))
      } else {
        store.send(.friendTapped(friend))
      }
    } label: {
      VStack(spacing: 4) {
        ZStack(alignment: .topTrailing) {
          FriendSticker(friend, height: 70, isSilhouette: stop == .later)
            .opacity(stop == .later ? 0.4 : 1)
            .saturation(isGrey(stop) ? 0 : 1)
            .padding(10)
            .background {
              Circle()
                .fill(Paper.paper)
                .overlay(
                  Circle().strokeBorder(stop == .reading ? Paper.red : Paper.rim, lineWidth: 4)
                )
                .shadow(color: Paper.shadow, radius: 4, y: 3)
            }
          if stop == .met || stop == .reading {
            Rosette(level: friend.level)
              .offset(x: 10, y: -8)
          }
        }
        Text(stop == .later ? "?" : friend.name)
          .font(Typography.display(17))
          .foregroundStyle(Paper.ink)
        if let tag = tag(stop) {
          Text(tag)
            .font(Typography.ui(12, weight: .semibold))
            .foregroundStyle(stop == .reading ? Paper.onRed : Paper.ink)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(stop == .reading ? Paper.red : Paper.wash, in: Capsule())
        }
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label(friend, stop))
    .accessibilityAddTraits(isTappable(stop) ? .isButton : .isStaticText)
  }

  private func isGrey(_ stop: JourneyMap.State.Stop) -> Bool {
    if case .next = stop { return true }
    return false
  }

  private func isTappable(_ stop: JourneyMap.State.Stop) -> Bool {
    switch stop {
    case .met, .next(true): true
    case .reading, .next(false), .later: false
    }
  }

  private func tag(_ stop: JourneyMap.State.Stop) -> String? {
    switch stop {
    case .reading: "reading"
    case .next(true): "big story waiting"
    case .next(false): "next"
    case .met, .later: nil
    }
  }

  private func label(_ friend: Friend, _ stop: JourneyMap.State.Stop) -> String {
    switch stop {
    case .reading: "\(friend.name), reading level \(friend.level). Reading now."
    case .met: "\(friend.name), reading level \(friend.level). Tap to read with \(friend.name)."
    case .next(true): "\(friend.name)'s big story is waiting."
    case .next(false): "\(friend.name) is next. Fill the path to meet them."
    case .later: "A friend at reading level \(friend.level)."
    }
  }
}

struct Rosette: View {
  let level: Int

  var body: some View {
    ZStack {
      Sticker("collect-rosette", height: 38)
      Text("\(level)")
        .font(Typography.display(13))
        .foregroundStyle(Paper.ink)
        .offset(y: -4)
    }
    .accessibilityHidden(true)
  }
}

struct TrailShape: Shape {
  let points: [CGPoint]

  static func controls(from: CGPoint, to: CGPoint) -> (CGPoint, CGPoint) {
    let middle = (from.y + to.y) / 2
    return (CGPoint(x: from.x, y: middle), CGPoint(x: to.x, y: middle))
  }

  static func point(from: CGPoint, to: CGPoint, at progress: Double) -> CGPoint {
    let (one, two) = controls(from: from, to: to)
    let t = CGFloat(min(max(progress, 0), 1))
    let u = 1 - t
    let a = u * u * u
    let b = 3 * u * u * t
    let c = 3 * u * t * t
    let d = t * t * t
    return CGPoint(
      x: a * from.x + b * one.x + c * two.x + d * to.x,
      y: a * from.y + b * one.y + c * two.y + d * to.y
    )
  }

  func path(in rect: CGRect) -> Path {
    var path = Path()
    guard let first = points.first else { return path }
    path.move(to: first)
    for (from, to) in zip(points, points.dropFirst()) {
      let (one, two) = Self.controls(from: from, to: to)
      path.addCurve(to: to, control1: one, control2: two)
    }
    return path
  }
}

#if DEBUG
struct JourneyMapPreview: View {
  var body: some View {
    JourneyMapScreen(store: store)
      .frame(width: Metrics.phone.reference.width, height: Metrics.phone.reference.height)
  }

  private var store: StoreOf<JourneyMap> {
    let saved = Content.Progress(journey: journey)
    return withDependencies {
      $0[ProgressStore.self] = ProgressStore(load: { saved }, save: { _ in })
    } operation: {
      Store(initialState: state) { JourneyMap() }
    }
  }

  private var journey: Journey {
    var journey = Journey(starting: .hare)
    journey.steps = 300
    return journey
  }

  private var state: JourneyMap.State {
    var state = JourneyMap.State()
    state.journey = journey
    return state
  }
}

#Preview { JourneyMapPreview() }
#endif
