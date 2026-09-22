import CoreGraphics

/// Layout numbers from `HANDOFF.md` §3, per device class.
///
/// The reading surface never moves: the word card, ball, mic pill and progress rail sit at these
/// coordinates on every stage. Phone numbers are given against the 390×844 reference and scale
/// proportionally on other iPhones.
public struct Metrics: Equatable, Sendable {
  public struct Card: Equatable, Sendable {
    public var origin: CGPoint
    public var size: CGSize
    public var cornerRadius: CGFloat
    public var ballLaneHeight: CGFloat
  }

  public struct WordSizes: Equatable, Sendable {
    public var current: CGFloat
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

  public static let phone = Metrics(
    reference: CGSize(width: 390, height: 844),
    topBarY: 48,
    sidePadding: 20,
    topBarHeight: 48,
    card: Card(
      origin: CGPoint(x: 16, y: 452),
      size: CGSize(width: 358, height: 196),
      cornerRadius: 34,
      ballLaneHeight: 78
    ),
    words: WordSizes(current: 64, side: 22, gap: 10),
    ballRadius: 19,
    ballRestAboveBaseline: 30,
    progressY: 674,
    progressWidth: 334,
    micPillY: 762,
    minimumTouchTarget: 48
  )

  public static let pad = Metrics(
    reference: CGSize(width: 1194, height: 834),
    topBarY: 32,
    sidePadding: 32,
    topBarHeight: 48,
    card: Card(
      origin: CGPoint(x: 147, y: 470),
      size: CGSize(width: 900, height: 236),
      cornerRadius: 44,
      ballLaneHeight: 78
    ),
    words: WordSizes(current: 100, side: 32, gap: 22),
    ballRadius: 26,
    ballRestAboveBaseline: 30,
    progressY: 736,
    progressWidth: 900,
    micPillY: 32,  // mic pill lives in the top bar on iPad
    minimumTouchTarget: 56
  )

  /// 1920×1080 with a 96pt overscan margin on all sides. The TV has no touch.
  public static let tv = Metrics(
    reference: CGSize(width: 1920, height: 1080),
    topBarY: 96,
    sidePadding: 96,
    topBarHeight: 48,
    card: Card(
      origin: CGPoint(x: 240, y: 560),
      size: CGSize(width: 1440, height: 300),
      cornerRadius: 56,
      ballLaneHeight: 78
    ),
    words: WordSizes(current: 144, side: 48, gap: 32),
    ballRadius: 34,
    ballRestAboveBaseline: 30,
    progressY: 900,
    progressWidth: 1440,
    micPillY: 96,
    minimumTouchTarget: 0
  )
}
