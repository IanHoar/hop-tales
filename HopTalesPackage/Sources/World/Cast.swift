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

final class DragonNode: SKNode {
  static let home: CGFloat = 2212
  static let scale: CGFloat = 0.72
  static let flapPeriod: CGFloat = 2.4
  static let roarTime: TimeInterval = 1.4

  let body: SKSpriteNode
  let wing: SKSpriteNode
  let calm: SKTexture?
  let roaring: SKTexture?
  private var clock: TimeInterval = 0
  private var sinceRoar: TimeInterval = .infinity

  override init() {
    let rigging = Rigging.dragon
    body = rigging.sprite("dragon-body-idle")
    wing = rigging.sprite("dragon-wing")
    calm = body.texture
    roaring = rigging.texture("dragon-body-roar")
    super.init()
    name = "dragon"
    let rig = SKNode()
    rig.setScale(Self.scale)
    rig.addChild(body)
    rig.addChild(wing)
    addChild(rig)
    position = Ground.point(at: Self.home)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  var isRoaring: Bool { sinceRoar < Self.roarTime }

  func roar() {
    sinceRoar = 0
  }

  func update(elapsed: TimeInterval) {
    clock += elapsed
    sinceRoar += elapsed
    let phase = sin(2 * .pi * CGFloat(clock) / Self.flapPeriod)
    let sweep: CGFloat = isRoaring ? 0.38 : 0.21
    wing.zRotation = -(phase * sweep) - 0.07
    body.texture = isRoaring ? roaring : calm
    body.yScale = 1 + 0.015 * sin(2 * .pi * CGFloat(clock) / 2.2)
  }
}
