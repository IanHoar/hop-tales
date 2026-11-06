import SwiftUI

public struct ConfettiCannon: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.freezesMotion) private var freezesMotion
  @State private var firedAt: Date?
  let delay: Double

  public init(delay: Double = 0) {
    self.delay = delay
  }

  static let duration = 4.6
  static let pieces = ConfettiPiece.burst(count: 140)

  public var body: some View {
    TimelineView(.animation(paused: firedAt == nil)) { timeline in
      Canvas { context, size in
        guard let firedAt else { return }
        let elapsed = timeline.date.timeIntervalSince(firedAt) - delay
        guard elapsed > 0, elapsed < Self.duration else { return }
        for piece in Self.pieces {
          piece.draw(at: elapsed, in: size, context: &context)
        }
      }
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
    .onAppear {
      guard !reduceMotion, !freezesMotion else { return }
      firedAt = .now
    }
  }
}

struct ConfettiPiece {
  enum Shape: CaseIterable {
    case square
    case strip
    case circle
    case ribbon
  }

  static let colours: [Color] = [
    Paper.red, Paper.wash, Paper.sage, Color(hex: 0x8FB7D9), Color(hex: 0xE8A7B8),
    Color(hex: 0xF2A65A), Color(hex: 0xB9A6E0)
  ]

  let fromLeft: Bool
  let angle: Double
  let speed: Double
  let launch: Double
  let shape: Shape
  let colour: Color
  let length: Double
  let spin: Double
  let flip: Double
  let flutter: Double
  let phase: Double

  static func burst(count: Int) -> [ConfettiPiece] {
    var random = SeededRandom(seed: 0x5EED_C0FE)
    return (0..<count).map { index in
      let fromLeft = index.isMultiple(of: 2)
      let tilt = random.next(in: 52...84)
      return ConfettiPiece(
        fromLeft: fromLeft,
        angle: (fromLeft ? 360 - tilt : 180 + tilt) * .pi / 180,
        speed: random.next(in: 2.6...4.4),
        launch: random.next(in: 0...0.22),
        shape: Shape.allCases[Int(random.next(in: 0...3.999))],
        colour: colours[Int(random.next(in: 0...Double(colours.count) - 0.001))],
        length: random.next(in: 8...16),
        spin: random.next(in: -9...9),
        flip: random.next(in: 4...12),
        flutter: random.next(in: 14...40),
        phase: random.next(in: 0...(2 * .pi))
      )
    }
  }

  func draw(at elapsed: Double, in size: CGSize, context: inout GraphicsContext) {
    let time = elapsed - launch
    guard time > 0 else { return }
    let drag = 3.0
    let gravity = size.height * 0.8
    let velocity = speed * size.height
    let vx = cos(angle) * velocity
    let vy = sin(angle) * velocity
    let slowed = (1 - exp(-drag * time)) / drag
    let settled = max(0, time - 0.7)
    var x = (fromLeft ? -10 : size.width + 10) + vx * slowed
    let y = size.height + 10 + gravity * time / drag + (vy - gravity / drag) * slowed
    x += sin(time * 3.2 + phase) * flutter * min(1, settled)
    let fade = min(1, (ConfettiCannon.duration - launch - time) / 0.7)
    guard y < size.height + 40, fade > 0 else { return }

    var piece = context
    piece.opacity = fade
    piece.translateBy(x: x, y: y)
    piece.rotate(by: .radians(spin * time + phase))
    piece.scaleBy(x: cos(flip * time + phase), y: 1)
    let rect: CGRect
    let path: Path
    switch shape {
    case .square:
      rect = CGRect(x: -length / 2, y: -length / 2, width: length, height: length * 0.8)
      path = Path(roundedRect: rect, cornerRadius: 1.5)
    case .strip:
      rect = CGRect(x: -length * 0.25, y: -length, width: length * 0.5, height: length * 2)
      path = Path(roundedRect: rect, cornerRadius: 1.5)
    case .circle:
      rect = CGRect(x: -length / 2.4, y: -length / 2.4, width: length / 1.2, height: length / 1.2)
      path = Path(ellipseIn: rect)
    case .ribbon:
      var curl = Path()
      curl.move(to: CGPoint(x: -length, y: 0))
      curl.addCurve(
        to: CGPoint(x: length, y: 0),
        control1: CGPoint(x: -length / 3, y: -length),
        control2: CGPoint(x: length / 3, y: length)
      )
      piece.stroke(curl, with: .color(colour), style: StrokeStyle(lineWidth: 3, lineCap: .round))
      return
    }
    piece.fill(path, with: .color(colour))
  }
}

struct SeededRandom {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed
  }

  mutating func next(in range: ClosedRange<Double>) -> Double {
    state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
    let unit = Double(state >> 11) / Double(1 << 53)
    return range.lowerBound + unit * (range.upperBound - range.lowerBound)
  }
}
