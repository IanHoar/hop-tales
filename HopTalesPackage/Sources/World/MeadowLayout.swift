import CoreGraphics

public enum MeadowLayer: CaseIterable, Sendable {
  case far
  case mid
  case near

  var asset: String {
    switch self {
    case .far: "far-day"
    case .mid: "mid-day"
    case .near: "near-day"
    }
  }

  var pixelSize: CGSize {
    switch self {
    case .far: CGSize(width: 5615, height: 826)
    case .mid: CGSize(width: 4692, height: 834)
    case .near: CGSize(width: 3555, height: 834)
    }
  }

  var speed: CGFloat {
    switch self {
    case .far: 0.3
    case .mid: 0.6
    case .near: 1
    }
  }

  var anchor: CGFloat {
    switch self {
    case .far: 986
    case .mid: 848
    case .near: 705
    }
  }
}

public struct MeadowLayout: Equatable, Sendable {
  public static let baseScale: CGFloat = 0.42

  public let size: CGSize
  public let scale: CGFloat

  public init(size: CGSize) {
    self.size = size
    let minSide = min(size.width, size.height)
    scale = Self.baseScale * max(1, minSide / 390 * 0.62)
  }

  public var k: CGFloat { scale / Self.baseScale }

  public func top(of layer: MeadowLayer) -> CGFloat {
    size.height - layer.anchor * scale
  }

  public func tileSize(of layer: MeadowLayer) -> CGSize {
    CGSize(width: layer.pixelSize.width * scale, height: layer.pixelSize.height * scale)
  }

  public var pathY: CGFloat { top(of: .near) + 430 * scale }
  public var sunWidth: CGFloat { 295 * scale }
  public var sunTop: CGFloat { size.height - 1224 * scale }
  public var moonSize: CGSize { CGSize(width: 150 * k, height: 162 * k) }
  public var moonCentre: CGPoint { CGPoint(x: size.width * 0.78, y: 150 * k) }

  public func offset(of layer: MeadowLayer, progress: Double) -> CGFloat {
    let width = tileSize(of: layer).width
    guard width > 0 else { return 0 }
    var travelled = (CGFloat(progress) * layer.speed).truncatingRemainder(dividingBy: width)
    if travelled < 0 { travelled += width }
    return -travelled
  }

  public func tileCount(of layer: MeadowLayer) -> Int {
    let width = tileSize(of: layer).width
    guard width > 0 else { return 1 }
    return Int((size.width / width).rounded(.up)) + 1
  }
}
