import SpriteKit
import UIKit

enum AmbientParticles {
  static let lifetime: CGFloat = 9
  static let onScreen: CGFloat = 10
  static let band: ClosedRange<CGFloat> = 250...430
  static let drift: CGFloat = 7
  static let sway: CGFloat = 6
  static let textureDiameter: CGFloat = 18

  static func colour(for stage: WorldStage) -> UIColor? {
    switch stage {
    case .meadow: UIColor(red: 1, green: 0.965, blue: 0.8, alpha: 1)
    case .castle: UIColor(red: 0.97, green: 0.86, blue: 0.64, alpha: 1)
    case .dragon: nil
    }
  }

  static func emitter() -> SKEmitterNode {
    let emitter = SKEmitterNode()
    emitter.particleTexture = SKTexture(image: disc())
    emitter.particleSize = CGSize(width: textureDiameter, height: textureDiameter)
    emitter.particleBirthRate = onScreen / lifetime
    emitter.particleLifetime = lifetime
    emitter.particleLifetimeRange = 3
    emitter.emissionAngle = .pi / 2
    emitter.emissionAngleRange = .pi / 8
    emitter.particleSpeed = drift
    emitter.particleSpeedRange = drift / 2
    emitter.particleScale = 0.84
    emitter.particleScaleRange = 0.32
    emitter.particleAlpha = 0
    emitter.particleAlphaSequence = SKKeyframeSequence(
      keyframeValues: [0, 0.9, 0.9, 0].map { NSNumber(value: $0) },
      times: [0, 0.15, 0.8, 1].map { NSNumber(value: $0) }
    )
    emitter.particleColorBlendFactor = 1
    let swing = SKAction.sequence([
      .moveBy(x: sway, y: 0, duration: 2.2),
      .moveBy(x: -sway, y: 0, duration: 2.2)
    ])
    swing.timingMode = .easeInEaseOut
    emitter.particleAction = .repeatForever(swing)
    return emitter
  }

  static func disc() -> UIImage {
    let size = CGSize(width: textureDiameter * 3, height: textureDiameter * 3)
    return UIGraphicsImageRenderer(size: size).image { context in
      let centre = CGPoint(x: size.width / 2, y: size.height / 2)
      let colours = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor]
      guard let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colours as CFArray,
        locations: [0, 1]
      ) else { return }
      context.cgContext.drawRadialGradient(
        gradient,
        startCenter: centre,
        startRadius: 0,
        endCenter: centre,
        endRadius: size.width / 2,
        options: []
      )
    }
  }
}
