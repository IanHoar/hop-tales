import CoreGraphics

public struct Metrics: Equatable, Sendable {
  public struct Card: Equatable, Sendable {
    public var origin: CGPoint
    public var size: CGSize
    public var cornerRadius: CGFloat
    public var ballLaneHeight: CGFloat
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
  public var topBarHeight: CGFloat
  public var card: Card
  public var words: WordSizes
  public var ballRadius: CGFloat
  public var ballRestAboveBaseline: CGFloat
  public var progressY: CGFloat
  public var progressWidth: CGFloat
  public var micPillY: CGFloat
  public var minimumTouchTarget: CGFloat
  public var pathScale: CGFloat = 1
  public var pathCentre: CGFloat = 640
  public static let phone = Metrics(
    reference: CGSize(width: 390, height: 844),
    topBarY: 48,
    sidePadding: 20,
    topBarHeight: 48,
    card: Card(
      origin: CGPoint(x: 14, y: 468),
      size: CGSize(width: 362, height: 168),
      cornerRadius: 32,
      ballLaneHeight: 78
    ),
    words: WordSizes(current: 54, recognised: 40, side: 31, gap: 12),
    ballRadius: 21,
    ballRestAboveBaseline: 30,
    progressY: 684,
    progressWidth: 334,
    micPillY: 766,
    minimumTouchTarget: 48
  )

  public static let pad = Metrics(
    reference: CGSize(width: 1194, height: 834),
    topBarY: 32,
    sidePadding: 32,
    topBarHeight: 48,
    card: Card(
      origin: CGPoint(x: 317, y: 470),
      size: CGSize(width: 560, height: 260),
      cornerRadius: 44,
      ballLaneHeight: 78
    ),
    words: WordSizes(current: 84, recognised: 62, side: 49, gap: 18),
    ballRadius: 26,
    ballRestAboveBaseline: 30,
    progressY: 736,
    progressWidth: 900,
    micPillY: 32,
    minimumTouchTarget: 56,
    pathScale: 1.15,
    pathCentre: 632
  )

  public static let tv = Metrics(
    reference: CGSize(width: 1920, height: 1080),
    topBarY: 96,
    sidePadding: 96,
    topBarHeight: 48,
    card: Card(
      origin: CGPoint(x: 240, y: 600),
      size: CGSize(width: 1440, height: 310),
      cornerRadius: 56,
      ballLaneHeight: 78
    ),
    words: WordSizes(current: 140, recognised: 100, side: 81, gap: 30),
    ballRadius: 38,
    ballRestAboveBaseline: 30,
    progressY: 930,
    progressWidth: 1440,
    micPillY: 96,
    minimumTouchTarget: 0
  )
}
