import Content
import SpriteKit

public enum IntroTimeline {
  public static let sunrise: TimeInterval = 0.6
  public static let sunriseLength: TimeInterval = 4
  public static let harePops: TimeInterval = 3.9
  public static let titleIn: TimeInterval = 4.2
  public static let hareTurns: TimeInterval = 5.6
  public static let hareRuns: TimeInterval = 6
  public static let runLength: TimeInterval = 1.15
  public static let titleOut: TimeInterval = 6.2
  public static let route: TimeInterval = 6.7
  public static let reducedRoute: TimeInterval = 0.3
  public static let launchFade: TimeInterval = 1
}

public final class IntroScene: SKScene {
  static let desaturation = """
    void main() {
      vec4 color = SKDefaultShading();
      float grey = dot(color.rgb, vec3(0.2125, 0.7154, 0.0721));
      gl_FragColor = vec4(mix(vec3(grey), color.rgb, u_saturation), color.a);
    }
    """

  let night = SKSpriteNode()
  let dawn = SKSpriteNode()
  let day = SKSpriteNode()
  let stars = SKNode()
  let glow = SKSpriteNode()
  let sun = SKSpriteNode(texture: MeadowArt.texture("sky-sun"))
  let clouds = [
    SKSpriteNode(texture: MeadowArt.texture("sky-cloud-2")),
    SKSpriteNode(texture: MeadowArt.texture("sky-cloud-3"))
  ]
  let land = SKNode()
  let saturation = SKUniform(name: "u_saturation", float: Float(IntroLayout.nightSaturation))
  private lazy var desaturated = SKShader(source: Self.desaturation, uniforms: [saturation])
  let layers = MeadowLayer.allCases.map { TiledLayer($0) }
  let hareFront = SKSpriteNode(texture: MeadowArt.texture("hare-front-sit"))
  let hareSide = SKSpriteNode(texture: MeadowArt.texture(Friend.hare.startingLook ?? "hare-sit"))
  let hareRun = SKSpriteNode()
  let launch: SKSpriteNode?
  let stretchesLaunch: Bool
  private let hopTextures: [SKTexture]
  public private(set) var isPlaying = false
  private var wantsToPlay = false
  private var layout = IntroLayout(meadow: MeadowLayout(size: .zero))

  public init(size: CGSize, launchImage: UIImage? = nil, stretchesLaunch: Bool = false) {
    let sheet = MeadowArt.texture(Friend.hare.startingLook.map { "\($0)-hop" } ?? "hare-hop")
    let frames = IntroLayout.hopFrames
    hopTextures = (0..<frames).map { index in
      let width = 1 / CGFloat(frames)
      let rect = CGRect(x: CGFloat(index) * width, y: 0, width: width, height: 1)
      return SKTexture(rect: rect, in: sheet)
    }
    launch = launchImage.map { SKSpriteNode(texture: SKTexture(image: $0)) }
    self.stretchesLaunch = stretchesLaunch
    super.init(size: size)
    anchorPoint = .zero
    scaleMode = .resizeFill
    backgroundColor = UIColor(rgb: 0x1E2A4E)
    build()
    relayout()
    preloadTextures()
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  private func build() {
    for node in [night, dawn, day] {
      node.anchorPoint = .zero
      addChild(node)
    }
    dawn.alpha = 0
    day.alpha = 0
    for index in IntroLayout.starSpots.indices {
      stars.addChild(SKSpriteNode(texture: MeadowArt.texture("sky-star-\(index % 3 + 1)")))
    }
    addChild(stars)
    glow.texture = SKTexture(image: Self.glowImage)
    glow.alpha = 0
    addChild(glow)
    addChild(sun)
    for cloud in clouds {
      cloud.alpha = 0
      addChild(cloud)
    }
    for layer in layers { land.addChild(layer) }
    addChild(land)
    hareRun.texture = hopTextures.first
    for hare in [hareFront, hareSide, hareRun] {
      hare.anchorPoint = CGPoint(x: 0.5, y: 0)
      hare.alpha = 0
      addChild(hare)
    }
    if let launch {
      launch.anchorPoint = .zero
      launch.zPosition = 10
      addChild(launch)
    }
  }

  override public func didChangeSize(_ oldSize: CGSize) {
    super.didChangeSize(oldSize)
    relayout()
  }

  private func relayout() {
    let zoom = launchZoom
    layout = IntroLayout(
      meadow: zoom > 1 ? MeadowLayout(size: size, k: zoom) : MeadowLayout(size: size)
    )
    guard !isPlaying else { return }
    placeSky()
    placeLand()
    placeHares()
    if launch != nil {
      launch?.size = launchFrame
      launch?.position = .zero
    }
  }

  private var launchZoom: CGFloat {
    guard !stretchesLaunch, let image = launch?.texture?.size(), image.width > 0 else { return 1 }
    return IntroLayout.launchSize(image, filling: size).width / image.width
  }

  private var launchFrame: CGSize {
    guard !stretchesLaunch, let image = launch?.texture?.size() else { return size }
    return IntroLayout.launchSize(image, filling: size)
  }

  private func placeSky() {
    let size = layout.size
    let frame = launchFrame
    let nightSize = CGSize(width: max(size.width, frame.width), height: frame.height)
    night.texture = SKTexture(image: MeadowArt.gradient(IntroLayout.night, size: nightSize))
    night.size = nightSize
    for (node, colors) in [(dawn, IntroLayout.dawn), (day, IntroLayout.day)] {
      node.texture = SKTexture(image: MeadowArt.gradient(colors, size: size))
      node.size = size
    }
    for (node, spot) in zip(stars.children, IntroLayout.starSpots) {
      guard let star = node as? SKSpriteNode else { continue }
      let width = spot.width * layout.k
      star.size = CGSize(width: width, height: width * MeadowStars.aspect)
      star.position = CGPoint(
        x: spot.x * frame.width + width / 2,
        y: frame.height * (1 - spot.top) - width / 2
      )
    }
    let sunWidth = layout.meadow.sunWidth
    let sunTexture = sun.texture?.size() ?? .zero
    let sunHeight = sunWidth * sunTexture.height / max(sunTexture.width, 1)
    sun.size = CGSize(width: sunWidth, height: sunHeight)
    sun.position = CGPoint(x: size.width / 2, y: sunCentreY(risen: false))
    glow.size = CGSize(width: sunWidth * 2.3, height: sunWidth * 2.3)
    glow.position = sun.position
    glow.setScale(0.8)
    let farTop = layout.meadow.top(of: .far)
    let spots = [
      IntroSpot(-0.08, farTop - 180 * layout.k, 130 * layout.k),
      IntroSpot(0.72, farTop - 250 * layout.k, 110 * layout.k)
    ]
    for (cloud, spot) in zip(clouds, spots) {
      let texture = cloud.texture?.size() ?? .zero
      let height = spot.width * texture.height / max(texture.width, 1)
      cloud.size = CGSize(width: spot.width, height: height)
      cloud.position = CGPoint(
        x: spot.x * size.width + spot.width / 2,
        y: layout.y(spot.top) - cloud.size.height / 2
      )
    }
  }

  private func sunCentreY(risen: Bool) -> CGFloat {
    let top = layout.meadow.sunTop + (risen ? -40 * layout.k : 170 * layout.k)
    return layout.y(top) - sun.size.height / 2
  }

  private func placeLand() {
    for layer in layers {
      layer.layout(layout.meadow, world: .hare, tint: IntroLayout.dimLand)
      layer.shade(desaturated)
      layer.scroll(layout.meadow, progress: layout.progress(of: layer.layer))
    }
    land.position.y = -layout.landDrop
  }

  private func placeHares() {
    let path = layout.y(layout.meadow.pathY + 8 * layout.k)
    let centre = layout.size.width / 2
    fit(hareFront, height: layout.hareFrontHeight)
    hareFront.position = CGPoint(x: centre, y: path)
    fit(hareSide, height: layout.hareSideHeight)
    hareSide.position = CGPoint(x: centre - hareSide.size.width * 0.02, y: path)
    let runHeight = layout.hareRunHeight
    let frame = IntroLayout.hopFrame
    hareRun.size = CGSize(width: runHeight * frame.width / frame.height, height: runHeight)
    hareRun.position = CGPoint(x: centre, y: path - layout.hareRunFeet)
  }

  private func fit(_ node: SKSpriteNode, height: CGFloat) {
    let texture = node.texture?.size() ?? .zero
    node.size = CGSize(width: height * texture.width / max(texture.height, 1), height: height)
  }

  public func play() {
    wantsToPlay = true
  }

  public var onFirstFrame: (() -> Void)?
  private var framesDrawn = 0
  private var texturesLoaded = false

  private func preloadTextures() {
    var textures = hopTextures
    enumerateChildNodes(withName: "//*") { node, _ in
      if let texture = (node as? SKSpriteNode)?.texture { textures.append(texture) }
    }
    SKTexture.preload(textures) { [weak self] in
      Task { @MainActor in self?.texturesLoaded = true }
    }
  }

  override public func didFinishUpdate() {
    super.didFinishUpdate()
    guard let onFirstFrame, texturesLoaded else { return }
    framesDrawn += 1
    guard framesDrawn >= 3 else { return }
    self.onFirstFrame = nil
    onFirstFrame()
  }

  override public func update(_ currentTime: TimeInterval) {
    guard wantsToPlay, !isPlaying, size.width > 0 else { return }
    isPlaying = true
    launch?.run(.sequence([
      .wait(forDuration: IntroTimeline.sunrise),
      .fadeOut(withDuration: IntroTimeline.launchFade),
      .removeFromParent()
    ]))
    playSunrise()
    playLand()
    playHare()
  }
}

extension IntroScene {
  fileprivate func after(_ delay: TimeInterval, _ action: SKAction) -> SKAction {
    .sequence([.wait(forDuration: delay), action])
  }

  fileprivate func playSunrise() {
    let start = IntroTimeline.sunrise
    let length = IntroTimeline.sunriseLength
    dawn.run(after(start, .fadeIn(withDuration: length * 0.45)))
    day.run(after(start + length * 0.4, .fadeIn(withDuration: length * 0.6)))
    stars.run(after(start, .fadeOut(withDuration: length * 0.55)))
    let rise = SKAction.moveTo(y: sunCentreY(risen: true), duration: length)
    rise.timingMode = .easeInEaseOut
    sun.run(after(start, rise))
    let glowRise = SKAction.group([
      rise,
      .scale(to: 1.1, duration: length),
      .sequence([.fadeIn(withDuration: length / 2), .fadeAlpha(to: 0.5, duration: length / 2)])
    ])
    glow.run(after(start, glowRise))
    for (index, cloud) in clouds.enumerated() {
      let drift = SKAction.moveBy(x: index == 0 ? 34 * layout.k : -26 * layout.k, y: 0, duration: 6)
      drift.timingMode = .easeOut
      cloud.position.x -= index == 0 ? 24 * layout.k : -20 * layout.k
      cloud.run(after(start, .group([drift, .fadeIn(withDuration: 1.9)])))
    }
  }

  fileprivate func playLand() {
    let start = IntroTimeline.sunrise
    let lift = SKAction.moveTo(y: 0, duration: IntroTimeline.sunriseLength)
    lift.timingMode = .easeInEaseOut
    land.run(after(start, lift))
    let length = IntroTimeline.sunriseLength
    let saturate = SKAction.customAction(withDuration: length) { [saturation] _, time in
      let progress = time / CGFloat(IntroTimeline.sunriseLength)
      let value = IntroLayout.nightSaturation + (1 - IntroLayout.nightSaturation) * progress
      saturation.floatValue = Float(value)
    }
    land.run(after(start, .sequence([
      saturate,
      .run { [weak self] in self?.layers.forEach { $0.shade(nil) } }
    ])))
    for (index, layer) in layers.enumerated() {
      layer.run(after(start + 0.12 * Double(index), .run { [weak layer] in
        layer?.tint(.white, duration: IntroTimeline.sunriseLength)
      }))
    }
  }

  fileprivate func playHare() {
    let pop = SKAction.sequence([
      .group([.fadeIn(withDuration: 0.2), .scaleX(to: 0.9, y: 1.08, duration: 0)]),
      .scaleX(to: 1.02, y: 0.98, duration: 0.3),
      .scale(to: 1, duration: 0.2),
      .wait(forDuration: IntroTimeline.hareTurns - IntroTimeline.harePops - 0.8),
      .scaleX(to: 0.82, y: 1.03, duration: 0.06),
      .group([.scaleX(to: 0.7, y: 1.03, duration: 0.04), .fadeOut(withDuration: 0.04)])
    ])
    hareFront.run(after(IntroTimeline.harePops, pop))
    let turn = SKAction.sequence([
      .group([.fadeIn(withDuration: 0.09), .scaleX(to: 1.03, y: 0.97, duration: 0.09)]),
      .scaleX(to: 0.97, y: 1.03, duration: 0.16),
      .scaleX(to: 1.06, y: 0.9, duration: 0.13),
      .fadeOut(withDuration: 0.02)
    ])
    hareSide.xScale = 0.75
    hareSide.run(after(IntroTimeline.hareTurns, turn))
    let frameTime = 1.0 / 14
    let distance = layout.size.width / 2 + hareRun.size.width
    let dash = SKAction.moveBy(x: distance, y: 0, duration: IntroTimeline.runLength)
    dash.timingMode = .easeIn
    let run = SKAction.sequence([
      .fadeIn(withDuration: 0),
      .group([dash, .repeat(.animate(with: hopTextures, timePerFrame: frameTime), count: 2)]),
      .fadeOut(withDuration: 0)
    ])
    hareRun.run(after(IntroTimeline.hareRuns, run))
  }

  static let glowImage: UIImage = {
    let side: CGFloat = 256
    return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { context in
      let colors = [
        UIColor(red: 1, green: 224 / 255, blue: 160 / 255, alpha: 0.85).cgColor,
        UIColor(red: 1, green: 210 / 255, blue: 150 / 255, alpha: 0.35).cgColor,
        UIColor(red: 1, green: 210 / 255, blue: 150 / 255, alpha: 0).cgColor
      ] as CFArray
      guard let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.55, 1]
      ) else { return }
      let centre = CGPoint(x: side / 2, y: side / 2)
      context.cgContext.drawRadialGradient(
        gradient,
        startCenter: centre, startRadius: 0,
        endCenter: centre, endRadius: side / 2,
        options: []
      )
    }
  }()
}
