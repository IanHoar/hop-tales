import ComposableArchitecture
import DesignSystem
import SwiftUI

enum FinishCheer {
  static let space = "finish-cheer"
  static let stars = 6
  static let start = WordPath.pan
  static let popSeconds: TimeInterval = 0.45
  static let popScale: CGFloat = 0.22
  static let burstSeconds: TimeInterval = 0.28
  static let flightSeconds: TimeInterval = 0.55
  static let stagger: TimeInterval = 0.06
  static let bumpSeconds: TimeInterval = 0.32
  static let bumpScale: CGFloat = 0.18
  static let fanDegrees: Double = 150
  static let arc: CGFloat = 0.35
  static let landedScale: CGFloat = 0.55
  static let starSize: CGFloat = 26
  static let reach: CGFloat = 54

  static var firstLanding: TimeInterval { start + burstSeconds + flightSeconds }
  static var lastLanding: TimeInterval { firstLanding + stagger * Double(stars - 1) }
  static var end: TimeInterval { lastLanding + bumpSeconds }

  struct Spark: Equatable {
    var centre: CGPoint
    var scale: CGFloat
  }

  static func wordScale(at elapsed: TimeInterval?) -> CGFloat {
    guard let elapsed else { return 1 }
    let progress = (elapsed - start) / popSeconds
    guard progress > 0, progress < 1 else { return 1 }
    return 1 + popScale * sin(.pi * progress)
  }

  static func chipScale(at elapsed: TimeInterval?) -> CGFloat {
    guard let elapsed else { return 1 }
    let progress = (elapsed - firstLanding) / (lastLanding - firstLanding + bumpSeconds)
    guard progress > 0, progress < 1 else { return 1 }
    return 1 + bumpScale * sin(.pi * progress)
  }

  static func spark(
    _ index: Int, at elapsed: TimeInterval, from: CGPoint, to: CGPoint, reach: CGFloat
  ) -> Spark? {
    let since = elapsed - start
    guard since >= 0 else { return nil }
    let angle = (-90 - fanDegrees / 2 + fanDegrees * Double(index) / Double(stars - 1)) * .pi / 180
    let burst = CGPoint(x: from.x + cos(angle) * reach, y: from.y + sin(angle) * reach)
    if since < burstSeconds {
      let out = easeOut(since / burstSeconds)
      return Spark(centre: mix(from, burst, out), scale: out)
    }
    let flight = (since - burstSeconds - stagger * Double(index)) / flightSeconds
    guard flight < 1 else { return nil }
    guard flight > 0 else { return Spark(centre: burst, scale: 1) }
    let eased = easeIn(flight)
    let distance = hypot(to.x - burst.x, to.y - burst.y)
    let control = CGPoint(x: (burst.x + to.x) / 2, y: min(burst.y, to.y) - distance * arc)
    let inverse = 1 - eased
    let centre = CGPoint(
      x: burst.x * inverse * inverse + control.x * 2 * inverse * eased + to.x * eased * eased,
      y: burst.y * inverse * inverse + control.y * 2 * inverse * eased + to.y * eased * eased
    )
    return Spark(centre: centre, scale: 1 - (1 - landedScale) * eased)
  }

  private static func mix(_ from: CGPoint, _ to: CGPoint, _ fraction: CGFloat) -> CGPoint {
    CGPoint(x: from.x + (to.x - from.x) * fraction, y: from.y + (to.y - from.y) * fraction)
  }

  private static func easeOut(_ value: Double) -> CGFloat {
    UnitCurve.easeOut.value(at: min(max(value, 0), 1))
  }

  private static func easeIn(_ value: Double) -> CGFloat {
    UnitCurve.easeIn.value(at: min(max(value, 0), 1))
  }
}

struct FinishedLayer: View {
  let store: StoreOf<Reading>
  let stars: Int
  let geometry: ReadingGeometry
  let finishedAt: Date?
  let lastWord: CGPoint?
  let isStill: Bool
  @State private var chipCentre: CGPoint?

  var body: some View {
    ZStack {
      StoryFinished(
        title: store.story.title,
        stars: stars,
        geometry: geometry,
        leadsHome: store.callout == nil,
        finishedAt: finishedAt,
        onStarChip: { chipCentre = $0 },
        readAgain: { store.send(.readAgainTapped) },
        done: { store.send(.backToStoriesTapped) }
      )
      .transition(.opacity.animation(.easeOut(duration: 0.4).delay(WordPath.pan)))
      if let finishedAt, let chipCentre, let lastWord, !isStill {
        FinishCheerBurst(finishedAt: finishedAt, from: lastWord, to: chipCentre, geometry: geometry)
      }
    }
    .frame(width: geometry.size.width, height: geometry.size.height)
  }
}

struct FinishCheerBurst: View {
  let finishedAt: Date
  let from: CGPoint
  let to: CGPoint
  let geometry: ReadingGeometry

  var body: some View {
    TimelineView(.animation) { context in
      let elapsed = context.date.timeIntervalSince(finishedAt)
      ZStack {
        ForEach(0..<FinishCheer.stars, id: \.self) { index in
          if let spark = FinishCheer.spark(
            index, at: elapsed, from: from, to: to, reach: geometry.path(FinishCheer.reach)
          ) {
            PaperStar(size: geometry.path(FinishCheer.starSize) * spark.scale)
              .position(spark.centre)
          }
        }
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}
