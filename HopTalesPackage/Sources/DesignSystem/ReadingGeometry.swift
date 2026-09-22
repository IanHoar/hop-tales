import CoreGraphics

public struct ReadingGeometry: Equatable, Sendable {
  public var metrics: Metrics
  public var size: CGSize

  public init(metrics: Metrics = .phone, size: CGSize) {
    self.metrics = metrics
    self.size = size
  }

  public var scale: CGFloat {
    guard metrics.reference.width > 0 else { return 1 }
    return size.width / metrics.reference.width
  }

  public func scaled(_ value: CGFloat) -> CGFloat { value * scale }

  public func y(_ value: CGFloat) -> CGFloat {
    guard metrics.reference.height > 0 else { return value }
    return size.height * (value / metrics.reference.height)
  }

  public var cardSize: CGSize {
    CGSize(width: scaled(metrics.card.size.width), height: scaled(metrics.card.size.height))
  }

  public var cardCenter: CGPoint {
    CGPoint(
      x: scaled(metrics.card.origin.x) + cardSize.width / 2,
      y: y(metrics.card.origin.y) + cardSize.height / 2
    )
  }

  public var cardCornerRadius: CGFloat { scaled(metrics.card.cornerRadius) }
  public var ballLaneHeight: CGFloat { scaled(metrics.card.ballLaneHeight) }
  public var currentWordSize: CGFloat { scaled(metrics.words.current) }
  public var sideWordSize: CGFloat { scaled(metrics.words.side) }
  public var wordGap: CGFloat { scaled(metrics.words.gap) }
  public var micPillY: CGFloat { y(metrics.micPillY) }
  public var progressY: CGFloat { y(metrics.progressY) }
  public var progressWidth: CGFloat { scaled(metrics.progressWidth) }
}
