import Content
import SpriteKit

final class MeadowSky: SKNode {
  private let back = SKSpriteNode()
  private let front = SKSpriteNode()
  private let sun = SKSpriteNode(texture: MeadowArt.texture("sky-sun"))
  private let moon = SKSpriteNode(texture: MeadowArt.texture("sky-moon"))
  private let stars = SKNode()
  private let fairClouds = SKNode()
  private let stormClouds = SKNode()
  private let overlay = SKSpriteNode(color: UIColor(rgb: 0x4E5A6E), size: .zero)
  private let flash = SKSpriteNode(color: .white, size: .zero)
  private let rain = RainNode()
  private let snow = SnowNode()
  private var layout = MeadowLayout(size: .zero)
  private var mood = Mood()
  private var untilFlash: TimeInterval = 6
  var drifts = true

  override init() {
    super.init()
    for node in [back, front] {
      node.anchorPoint = .zero
      addChild(node)
    }
    front.alpha = 0
    [stars, moon, sun, fairClouds, stormClouds].forEach(addChild)
    overlay.anchorPoint = .zero
    flash.anchorPoint = .zero
    flash.alpha = 0
    buildClouds()
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  var weatherNodes: [SKNode] { [overlay, rain, snow, flash] }

  var starAlpha: CGFloat { stars.alpha }
  var rainIsFalling: Bool { rain.isFalling }

  private func buildClouds() {
    let fair = ["sky-cloud-1", "sky-cloud-2", "sky-cloud-3", "sky-cloud-4"]
    let storm = ["sky-storm-1", "sky-storm-2", "sky-storm-3"]
    for (index, name) in fair.enumerated() {
      fairClouds.addChild(cloud(name, slot: index, of: fair.count))
    }
    for (index, name) in storm.enumerated() {
      stormClouds.addChild(cloud(name, slot: index, of: storm.count))
    }
  }

  private func cloud(_ name: String, slot: Int, of count: Int) -> SKSpriteNode {
    let node = SKSpriteNode(texture: MeadowArt.texture(name))
    node.name = name
    node.userData = ["slot": CGFloat(slot) / CGFloat(count), "speed": CGFloat(6 + 3 * slot)]
    return node
  }

  private func placeStars() {
    stars.removeAllChildren()
    let height = layout.size.height
    for star in MeadowStars.field(for: layout) {
      let node = SKSpriteNode(texture: MeadowArt.texture(star.asset))
      node.size = CGSize(width: star.width, height: star.width * MeadowStars.aspect)
      node.position = CGPoint(x: star.centre.x, y: height - star.centre.y)
      stars.addChild(node)
    }
  }

  func layout(_ layout: MeadowLayout) {
    self.layout = layout
    let size = layout.size
    for node in [back, front, overlay, flash] {
      node.size = size
    }
    back.texture = gradient(mood.sky)
    rain.layout(size)
    snow.layout(size)
    let sunSize = sun.texture?.size() ?? .zero
    sun.size = CGSize(
      width: layout.sunWidth,
      height: layout.sunWidth * sunSize.height / max(sunSize.width, 1)
    )
    moon.size = layout.moonSize
    moon.position = CGPoint(x: layout.moonCentre.x, y: size.height - layout.moonCentre.y)
    placeSun()
    placeStars()
    for case let cloud as SKSpriteNode in fairClouds.children + stormClouds.children {
      let texture = cloud.texture?.size() ?? .zero
      let scale = 0.5 * layout.k
      cloud.size = CGSize(width: texture.width * scale, height: texture.height * scale)
      let slot = cloud.userData?["slot"] as? CGFloat ?? 0
      cloud.position = CGPoint(
        x: slot * (size.width + cloud.size.width),
        y: size.height - (70 + 130 * slot) * layout.k
      )
    }
  }

  private func placeSun() {
    let drop = mood.sky.style.sunDrop * layout.k
    sun.position = CGPoint(
      x: layout.size.width * 0.24,
      y: layout.size.height - layout.sunTop - sun.size.height / 2 - drop
    )
  }

  private func gradient(_ sky: Sky) -> SKTexture {
    let size = CGSize(width: 8, height: max(layout.size.height, 8))
    return SKTexture(image: MeadowArt.gradient(sky.style.gradient, size: size))
  }

  func apply(_ mood: Mood, duration: TimeInterval) {
    let skyChanged = mood.sky != self.mood.sky
    self.mood = mood
    let sky = mood.sky.style
    let weather = mood.weather.style
    if skyChanged {
      front.texture = gradient(mood.sky)
      front.alpha = 0
      front.run(.sequence([
        .fadeIn(withDuration: duration),
        .run { [weak self] in
          guard let self else { return }
          back.texture = front.texture
          front.alpha = 0
        }
      ]))
    }
    fade(stars, to: sky.stars, duration)
    fade(moon, to: sky.moon, duration)
    fade(sun, to: sky.sun * weather.sun, duration)
    sun.run(.move(
      to: CGPoint(
        x: layout.size.width * 0.24,
        y: layout.size.height - layout.sunTop - sun.size.height / 2 - sky.sunDrop * layout.k
      ),
      duration: duration
    ))
    fade(fairClouds, to: weather.fairClouds * sky.clouds, duration)
    fade(stormClouds, to: weather.stormClouds * sky.clouds, duration)
    fade(overlay, to: weather.overlay, duration)
    rain.isFalling = weather.rain
    snow.isFalling = weather.snow
  }

  private func fade(_ node: SKNode, to alpha: CGFloat, _ duration: TimeInterval) {
    node.removeAction(forKey: "fade")
    if duration > 0 {
      node.run(.fadeAlpha(to: alpha, duration: duration), withKey: "fade")
    } else {
      node.alpha = alpha
    }
  }

  func update(_ elapsed: TimeInterval) {
    guard drifts else { return }
    let width = layout.size.width
    for case let cloud as SKSpriteNode in fairClouds.children + stormClouds.children {
      let speed = cloud.userData?["speed"] as? CGFloat ?? 6
      cloud.position.x -= speed * layout.k * CGFloat(elapsed)
      if cloud.position.x < -cloud.size.width / 2 {
        cloud.position.x = width + cloud.size.width / 2
      }
    }
    guard mood.weather.style.lightning else { return }
    untilFlash -= elapsed
    if untilFlash <= 0 {
      untilFlash = .random(in: 4...9)
      flash.run(.sequence([.fadeAlpha(to: 0.55, duration: 0.05), .fadeOut(withDuration: 0.35)]))
    }
  }
}

final class RainNode: SKNode {
  private let emitters = [SKEmitterNode(), SKEmitterNode()]

  var isFalling = false {
    didSet {
      for (index, emitter) in emitters.enumerated() {
        emitter.particleBirthRate = isFalling ? (index == 0 ? 90 : 55) : 0
      }
    }
  }

  override init() {
    super.init()
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 26))
    let streak = SKTexture(image: renderer.image { context in
      UIColor(white: 1, alpha: 0.7).setFill()
      context.fill(CGRect(x: 0, y: 0, width: 2, height: 26))
    })
    for (index, emitter) in emitters.enumerated() {
      emitter.particleTexture = streak
      emitter.particleBirthRate = 0
      emitter.particleLifetime = 2.2
      emitter.particleSpeed = index == 0 ? 620 : 440
      emitter.particleAlpha = index == 0 ? 0.55 : 0.35
      emitter.particleScale = index == 0 ? 1 : 0.7
      emitter.emissionAngle = -.pi / 2 - 0.26
      emitter.particleRotation = -0.26
      addChild(emitter)
    }
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  func layout(_ size: CGSize) {
    for emitter in emitters {
      emitter.position = CGPoint(x: size.width * 0.6, y: size.height + 20)
      emitter.particlePositionRange = CGVector(dx: size.width * 1.6, dy: 0)
    }
  }
}

final class SnowNode: SKNode {
  private let emitters = [SKEmitterNode(), SKEmitterNode()]

  var isFalling = false {
    didSet {
      for (index, emitter) in emitters.enumerated() {
        emitter.particleBirthRate = isFalling ? (index == 0 ? 14 : 22) : 0
      }
    }
  }

  override init() {
    super.init()
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
    let flake = SKTexture(image: renderer.image { context in
      UIColor(white: 1, alpha: 0.9).setFill()
      context.cgContext.fillEllipse(in: CGRect(x: 1, y: 1, width: 8, height: 8))
    })
    for (index, emitter) in emitters.enumerated() {
      emitter.particleTexture = flake
      emitter.particleBirthRate = 0
      emitter.particleLifetime = 9
      emitter.particleSpeed = index == 0 ? 70 : 45
      emitter.particleSpeedRange = 20
      emitter.particleAlpha = index == 0 ? 0.9 : 0.6
      emitter.particleScale = index == 0 ? 0.9 : 0.5
      emitter.particleScaleRange = 0.3
      emitter.emissionAngle = -.pi / 2
      emitter.emissionAngleRange = 0.5
      emitter.xAcceleration = -6
      addChild(emitter)
    }
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  func layout(_ size: CGSize) {
    for emitter in emitters {
      emitter.position = CGPoint(x: size.width * 0.5, y: size.height + 12)
      emitter.particlePositionRange = CGVector(dx: size.width * 1.4, dy: 0)
    }
  }
}
