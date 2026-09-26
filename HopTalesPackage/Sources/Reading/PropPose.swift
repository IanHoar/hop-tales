import Content
import Foundation

struct PropPose: Equatable {
  var dx: CGFloat = 0
  var dy: CGFloat = 0
  var rotation: Double = 0
  var scale: CGFloat = 1
  var opacity: Double = 1
  var frame = 1
  var flip = false
  var pivotsAtBase = true

  static func at(
    item: PropItem, elapsed: TimeInterval?, exit: Double, width: CGFloat, unit: CGFloat
  ) -> PropPose {
    guard let elapsed else { return PropPose() }
    guard elapsed >= 0 else { return PropPose(opacity: 0) }
    var pose = moving(item: item, time: elapsed, width: width, unit: unit)
    pose.opacity *= 1 - exit
    return pose
  }

  private static func moving(
    item: PropItem, time: TimeInterval, width: CGFloat, unit: CGFloat
  ) -> PropPose {
    switch item.prop.motion {
    case .walk, .swim, .fly, .swoop, .perch:
      travelling(item: item, time: time, width: width, unit: unit)
    case .pop, .burst, .drift, .sway, .roll, .bob, .fade:
      settling(item: item, time: time, width: width, unit: unit)
    }
  }

  private static func travelling(
    item: PropItem, time: TimeInterval, width: CGFloat, unit: CGFloat
  ) -> PropPose {
    let phase = Double(item.seed % 5)
    switch item.prop.motion {
    case .walk:
      return walk(time: time, distance: width * 0.6, unit: unit)
    case .swim:
      var pose = walk(time: time, distance: width * 0.5, unit: unit)
      pose.frame = Int(time / 0.3) % 2 + 1
      pose.dy = sin(time * 2.2 + phase) * 3 * unit
      return pose
    case .fly:
      return fly(item: item, time: time, width: width, unit: unit)
    case .swoop:
      return swoop(item: item, time: time, width: width, unit: unit)
    default:
      return perch(time: time, width: width, unit: unit)
    }
  }

  private static func settling(
    item: PropItem, time: TimeInterval, width: CGFloat, unit: CGFloat
  ) -> PropPose {
    let phase = Double(item.seed % 5)
    switch item.prop.motion {
    case .pop:
      return PropPose(scale: popScale(time))
    case .burst:
      let fade = min(1, max(0, (time - 1.2) / 0.6))
      return PropPose(scale: popScale(time), opacity: 1 - fade)
    case .drift:
      let arrive = easeOut(min(1, time / 3.2))
      return PropPose(
        dx: (1 - arrive) * width * 0.5,
        dy: sin(time * 1.3 + phase) * 6 * unit,
        rotation: sin(time * 0.9 + phase) * 4,
        pivotsAtBase: false
      )
    case .sway:
      return PropPose(rotation: sin(time * 1.1 + phase) * 2.5, scale: popScale(time))
    case .roll:
      let arrive = easeOut(min(1, time / 1.8))
      let dx = (1 - arrive) * width * 0.5
      let radius = max(item.height * 0.5 * unit, 1)
      return PropPose(dx: dx, rotation: -Double(dx / radius) * 180 / .pi, pivotsAtBase: false)
    case .bob:
      return PropPose(
        dy: sin(time * 1.6 + phase) * 3 * unit,
        rotation: sin(time * 1.2 + phase) * 3,
        scale: popScale(time),
        pivotsAtBase: false
      )
    default:
      return PropPose(opacity: min(1, time / 1.2))
    }
  }

  private static func walk(time: TimeInterval, distance: CGFloat, unit: CGFloat) -> PropPose {
    let progress = min(1, time / 2.4)
    let moving = progress < 1
    let step = Int(time / 0.16)
    return PropPose(
      dx: (1 - easeOut(progress)) * distance,
      dy: moving ? -abs(sin(time * .pi / 0.16)) * 2 * unit : 0,
      frame: moving ? step % 2 + 1 : 1
    )
  }

  private static func fly(
    item: PropItem, time: TimeInterval, width: CGFloat, unit: CGFloat
  ) -> PropPose {
    let style = FlightStyle(name: item.name, seed: item.seed)
    let progress = time / style.duration
    guard progress < 1 else { return PropPose(opacity: 0) }
    let start = width - item.anchor + 40 * unit
    let travel = width + 80 * unit
    let curl = style.curl * unit
    let dx = start - travel * progress + curl * cos(time * style.spin)
    let dy = -curl * sin(time * style.spin) + style.wander * unit * sin(time * 1.1 + style.phase)
    let fadeIn = min(1, time / 0.4)
    let fadeOut = min(1, (style.duration - time) / 0.4)
    var opacity = fadeIn * fadeOut
    if item.name == "firefly" { opacity *= 0.65 + 0.35 * sin(time * 3 + style.phase) }
    return PropPose(
      dx: dx,
      dy: dy,
      rotation: sin(time * style.spin) * style.tilt,
      opacity: opacity,
      frame: Int(time / style.flap) % 2 + 1,
      pivotsAtBase: false
    )
  }

  private static func swoop(
    item: PropItem, time: TimeInterval, width: CGFloat, unit: CGFloat
  ) -> PropPose {
    let duration = 5.5
    let progress = time / duration
    guard progress < 1 else { return PropPose(opacity: 0) }
    let start = width - item.anchor + 60 * unit
    let travel = width + 120 * unit
    return PropPose(
      dx: start - travel * progress,
      dy: -46 * unit * sin(.pi * progress) + 8 * unit * sin(time * 2),
      rotation: -5 * cos(.pi * progress),
      opacity: min(1, time / 0.4) * min(1, (duration - time) / 0.4),
      frame: Int(time / 0.26) % 2 + 1,
      pivotsAtBase: false
    )
  }

  private static func perch(time: TimeInterval, width: CGFloat, unit: CGFloat) -> PropPose {
    let arrive = min(1, time / 2.2)
    let eased = arrive * arrive * (3 - 2 * arrive)
    let curve = sin(.pi * eased) * 34 * unit
    return PropPose(
      dx: (1 - eased) * width * 0.45 - curve,
      dy: -(1 - eased) * 130 * unit - curve * 0.5 + sin(time * 1.6) * 4 * unit,
      opacity: min(1, time / 0.3),
      frame: Int(time / (arrive < 1 ? 0.14 : 0.55)) % 2 + 1,
      pivotsAtBase: false
    )
  }

  private static func popScale(_ time: TimeInterval) -> CGFloat {
    let progress = min(1, time / 0.5)
    let overshoot = 1.70158
    let shifted = progress - 1
    return 1 + (overshoot + 1) * pow(shifted, 3) + overshoot * pow(shifted, 2)
  }

  private static func easeOut(_ progress: Double) -> Double {
    1 - (1 - progress) * (1 - progress)
  }
}

struct FlightStyle {
  let duration: Double
  let curl: Double
  let spin: Double
  let wander: Double
  let flap: Double
  let tilt: Double
  let phase: Double

  init(name: String, seed: Int) {
    phase = Double(seed % 7)
    switch name {
    case "bee":
      (duration, curl, spin, wander, flap, tilt) = (5, 10, 6, 14, 0.05, 6)
    case "dragonfly":
      (duration, curl, spin, wander, flap, tilt) = (4, 6, 2.2, 22, 0.05, 4)
    case "firefly":
      (duration, curl, spin, wander, flap, tilt) = (8, 16, 1.8, 18, 0.12, 5)
    case "ladybird":
      (duration, curl, spin, wander, flap, tilt) = (6, 12, 4.5, 16, 0.06, 8)
    default:
      let turn = 3.4 + Double(seed % 3) * 0.3
      (duration, curl, spin, wander, flap, tilt) = (7, 22, turn, 26, 0.09, 10)
    }
  }
}
