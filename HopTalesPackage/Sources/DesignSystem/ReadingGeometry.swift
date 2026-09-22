import CoreGraphics

/// Maps the handoff's fixed layout numbers onto the screen it is actually running on.
///
/// The spec gives phone coordinates against a 390×844 reference and says to scale proportionally.
/// Sizes scale with width, so the card keeps its proportion of the screen; vertical positions scale
/// with height, so the card stays at the same point down a taller or shorter phone.
public struct ReadingGeometry: Equatable, Sendable {
  public var metrics: Metrics
  public var size: CGSize

  public init(metrics: Metrics = .phone, size: CGSize) {
    self.metrics = metrics
    self.size = size
  }

  /// Scale for anything with a width, a height or a font size.
  public var scale: CGFloat {
    guard metrics.reference.width > 0 else { return 1 }
    return size.width / metrics.reference.width
  }

  public func scaled(_ value: CGFloat) -> CGFloat { value * scale }

  /// Scale for a y coordinate given as a distance down the reference screen.
  public func y(_ value: CGFloat) -> CGFloat {
    guard metrics.reference.height > 0 else { return value }
    return size.height * (value / metrics.reference.height)
  }

  public var cardSize: CGSize {
    CGSize(width: scaled(metrics.card.size.width), height: scaled(metrics.card.size.height))
  }

  /// The card's centre, which is where it is placed from.
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
}
