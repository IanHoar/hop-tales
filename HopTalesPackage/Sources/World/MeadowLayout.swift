import Content
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

  @MainActor
  func asset(in world: Friend) -> String {
    let own = "\(asset.prefix { $0 != "-" })-\(world.rawValue)"
    return world != .hare && MeadowArt.image(own) != nil ? own : asset
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

  var pathScale: CGFloat {
    switch self {
    case .far: 0.42
    case .mid: 0.5
    case .near: 0.74
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

public enum MeadowFraming: Hashable, Sendable {
  case wide
  case path(scale: CGFloat, centre: CGFloat)
}

public struct MeadowLayout: Equatable, Sendable {
  public static let baseScale: CGFloat = 0.42
  public static let pathLine: CGFloat = 440

  public let size: CGSize
  public let scale: CGFloat
  public let framing: MeadowFraming

  public init(size: CGSize, framing: MeadowFraming = .wide) {
    self.size = size
    self.framing = framing
    switch framing {
    case .wide:
      let minSide = min(size.width, size.height)
      scale = Self.baseScale * max(1, minSide / 390 * 0.62)
    case let .path(pathScale, _):
      scale = Self.baseScale * pathScale
    }
  }

  public var k: CGFloat { scale / Self.baseScale }

  public func scale(of layer: MeadowLayer) -> CGFloat {
    guard case .path = framing else { return scale }
    return k * layer.pathScale
  }

  public func top(of layer: MeadowLayer) -> CGFloat {
    guard case let .path(_, centre) = framing else { return size.height - layer.anchor * scale }
    let near = centre - Self.pathLine * scale(of: .near)
    switch layer {
    case .far: return near - 52 * k
    case .mid: return near + 8 * k
    case .near: return near
    }
  }

  public func tileSize(of layer: MeadowLayer) -> CGSize {
    let scale = scale(of: layer)
    return CGSize(width: layer.pixelSize.width * scale, height: layer.pixelSize.height * scale)
  }

  public var showsProps: Bool { framing == .wide }
  public var pathY: CGFloat { top(of: .near) + 430 * scale(of: .near) }
  public var pathCentre: CGFloat { top(of: .near) + Self.pathLine * scale(of: .near) }
  public var sunWidth: CGFloat { 295 * scale }
  public var sunTop: CGFloat { top(of: .far) - 238 * scale }
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
