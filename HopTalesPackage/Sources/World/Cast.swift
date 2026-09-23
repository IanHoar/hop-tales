import SpriteKit
import UIKit

enum Ground {
  static func height(at x: CGFloat) -> CGFloat {
    WorldMetrics.size.height - (448 - 10 * sin(x / 190) - 6 * sin(x / 63 + 1))
  }

  static func point(at x: CGFloat) -> CGPoint {
    CGPoint(x: x, y: height(at: x))
  }
}

final class KnightNode: SKNode {
  static let home: CGFloat = 1262
  static let scale: CGFloat = 0.6
  static let waveReach: CGFloat = 120
  static let waveTime: TimeInterval = 1.2

  let body: SKSpriteNode
  let idle: SKTexture?
  let waving: SKTexture?
  private(set) var hasWaved = false
  private var clock: TimeInterval = 0
  private var sinceWave: TimeInterval = .infinity

  override init() {
    let rigging = Rigging.knight
    body = rigging.sprite("knight-idle")
    idle = body.texture
    waving = rigging.texture("knight-wave")
    super.init()
    name = "knight"
    body.setScale(Self.scale)
    addChild(body)
    position = Ground.point(at: Self.home)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  func update(elapsed: TimeInterval, foxAt foxX: CGFloat) {
    clock += elapsed
    sinceWave += elapsed
    if !hasWaved, abs(foxX - Self.home) < Self.waveReach {
      hasWaved = true
      sinceWave = 0
    }
    body.texture = sinceWave < Self.waveTime ? waving : idle
    body.yScale = Self.scale * (1 + 0.012 * sin(2 * .pi * CGFloat(clock) / 1.2))
  }
}

@MainActor
enum DragonSheet {
  static let columns = 5
  static let rows = 4
  static let frameSize: CGFloat = 256
  static let feet: CGFloat = 218

  static let image = UIImage(named: "dragon-idle", in: .module, compatibleWith: nil)

  static let frames: [SKTexture] = {
    guard let image else { return [] }
    let sheet = SKTexture(image: image)
    sheet.filteringMode = .nearest
    return (0..<rows).flatMap { row in
      (0..<columns).map { column in
        let rect = CGRect(
          x: CGFloat(column) / CGFloat(columns),
          y: 1 - CGFloat(row + 1) / CGFloat(rows),
          width: 1 / CGFloat(columns),
          height: 1 / CGFloat(rows)
        )
        let frame = SKTexture(rect: rect, in: sheet)
        frame.filteringMode = .nearest
        return frame
      }
    }
  }()

  static var portrait: UIImage? {
    guard let cgImage = image?.cgImage,
      let frame = cgImage.cropping(to: CGRect(x: 0, y: 0, width: frameSize, height: frameSize))
    else { return nil }
    return UIImage(cgImage: frame, scale: 1, orientation: .upMirrored)
  }
}

final class DragonNode: SKNode {
  static let home: CGFloat = 2212
  static let scale: CGFloat = 1.05
  static let framesPerSecond: Double = 10
  static let roarTime: TimeInterval = 1.4

  let body: SKSpriteNode
  let frames: [SKTexture]
  private var clock: TimeInterval = 0
  private var sinceRoar: TimeInterval = .infinity

  override init() {
    frames = DragonSheet.frames
    body = SKSpriteNode(
      texture: frames.first,
      size: CGSize(width: DragonSheet.frameSize, height: DragonSheet.frameSize)
    )
    super.init()
    name = "dragon"
    body.anchorPoint = CGPoint(x: 0.5, y: 1 - DragonSheet.feet / DragonSheet.frameSize)
    body.xScale = -Self.scale
    body.yScale = Self.scale
    addChild(body)
    position = Ground.point(at: Self.home)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  var isRoaring: Bool { sinceRoar < Self.roarTime }

  var frameIndex: Int {
    guard !frames.isEmpty else { return 0 }
    return Int(clock * Self.framesPerSecond + 0.000_1) % frames.count
  }

  func roar() {
    sinceRoar = 0
  }

  func update(elapsed: TimeInterval) {
    sinceRoar += elapsed
    clock += isRoaring ? elapsed * 2 : elapsed
    if !frames.isEmpty {
      body.texture = frames[frameIndex]
    }
    let pulse = isRoaring ? 0.08 * sin(.pi * CGFloat(sinceRoar / Self.roarTime)) : 0
    body.xScale = -Self.scale * (1 + pulse)
    body.yScale = Self.scale * (1 + pulse)
  }
}
