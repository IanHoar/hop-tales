import CoreGraphics

public struct Metrics: Equatable, Sendable {
  public struct Card: Equatable, Sendable {
    public var origin: CGPoint
    public var size: CGSize
  }

  public struct WordSizes: Equatable, Sendable {
    public var current: CGFloat
    public var recognised: CGFloat
    public var side: CGFloat
    public var gap: CGFloat
  }

  public var reference: CGSize
  public var topBarY: CGFloat
  public var sidePadding: CGFloat
  public var card: Card
  public var words: WordSizes
  public var pathScale: CGFloat = 1
  public var pathCentre: CGFloat = 640
  public static let phone = Metrics(
    reference: CGSize(width: 390, height: 844),
    topBarY: 48,
    sidePadding: 20,
    card: Card(
      origin: CGPoint(x: 14, y: 468),
      size: CGSize(width: 362, height: 168)
    ),
    words: WordSizes(current: 54, recognised: 40, side: 31, gap: 12)
  )

  public static let pad = Metrics(
    reference: CGSize(width: 1194, height: 834),
    topBarY: 32,
    sidePadding: 32,
    card: Card(
      origin: CGPoint(x: 317, y: 470),
      size: CGSize(width: 560, height: 260)
    ),
    words: WordSizes(current: 84, recognised: 62, side: 49, gap: 18),
    pathScale: 1.15,
    pathCentre: 632
  )

  public static let tv = Metrics(
    reference: CGSize(width: 1920, height: 1080),
    topBarY: 96,
    sidePadding: 96,
    card: Card(
      origin: CGPoint(x: 240, y: 600),
      size: CGSize(width: 1440, height: 310)
    ),
    words: WordSizes(current: 140, recognised: 100, side: 81, gap: 30)
  )
}
