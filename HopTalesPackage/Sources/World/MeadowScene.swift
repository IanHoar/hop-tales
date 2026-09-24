import Content
import SpriteKit

public final class MeadowScene: SKScene {
  public static let settle: Double = 2.4
  public static let moodCrossfade: TimeInterval = 3

  let sky = MeadowSky()
  let land = SKNode()
  let props = PropLayer()
  let layers = MeadowLayer.allCases.map { TiledLayer($0) }
  public private(set) var meadow = MeadowLayout(size: .zero)
  public private(set) var mood = Mood()
  public private(set) var target: Double = 0
  public private(set) var shown: Double = 0
  public private(set) var pan: MeadowCamera?
  public var framing = MeadowFraming.wide {
    didSet { if framing != oldValue { relayout() } }
  }
  private var lastUpdate: TimeInterval?

  override public init(size: CGSize) {
    super.init(size: size)
    anchorPoint = .zero
    scaleMode = .resizeFill
    backgroundColor = .clear
    addChild(sky)
    addChild(land)
    for layer in layers {
      land.addChild(layer)
      if layer.layer == .near { land.addChild(props) }
    }
    sky.weatherNodes.forEach(addChild)
    relayout()
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override public func didChangeSize(_ oldSize: CGSize) {
    super.didChangeSize(oldSize)
    relayout()
  }

  private func relayout() {
    meadow = MeadowLayout(size: size, framing: framing)
    sky.layout(meadow)
    for layer in layers {
      layer.layout(meadow, tint: mood.tint(for: layer.layer))
    }
    props.reset()
    props.isHidden = !meadow.showsProps
    scroll(to: shown)
  }

  public var drifts: Bool {
    get { sky.drifts }
    set { sky.drifts = newValue }
  }

  public func setProgress(_ progress: Double, animated: Bool = true) {
    target = progress
    if !animated {
      scroll(to: progress)
    }
  }

  public func setCamera(_ camera: MeadowCamera) {
    pan = camera
    target = camera.to
    scroll(to: camera.x(at: MeadowCamera.now))
  }

  public func setMood(_ mood: Mood, animated: Bool = true) {
    let duration = animated ? Self.moodCrossfade : 0
    self.mood = mood
    sky.apply(mood, duration: duration)
    for layer in layers {
      layer.tint(mood.tint(for: layer.layer), duration: duration)
    }
    props.tint(mood.tint(for: .near), duration: duration)
  }

  private func scroll(to progress: Double) {
    shown = progress
    for layer in layers {
      layer.scroll(meadow, progress: progress)
    }
    if meadow.showsProps { props.scroll(meadow, progress: progress) }
  }

  override public func update(_ currentTime: TimeInterval) {
    let elapsed = lastUpdate.map { min(currentTime - $0, 0.1) } ?? 0
    lastUpdate = currentTime
    sky.update(elapsed)
    if let pan {
      let x = pan.x(at: currentTime)
      if x != shown { scroll(to: x) }
      return
    }
    guard abs(target - shown) > 0.1 else {
      if target != shown { scroll(to: target) }
      return
    }
    scroll(to: shown + (target - shown) * min(1, elapsed * Self.settle))
  }
}
