import Dependencies
import Foundation

public struct SoundPreference: Sendable {
  public var load: @Sendable () -> Bool
  public var save: @Sendable (Bool) -> Void

  public init(load: @escaping @Sendable () -> Bool, save: @escaping @Sendable (Bool) -> Void) {
    self.load = load
    self.save = save
  }
}

extension SoundPreference: DependencyKey {
  public static let key = "sound-on"

  public static func stored(in suiteName: String? = nil) -> SoundPreference {
    @Sendable func defaults() -> UserDefaults {
      suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }
    return SoundPreference(
      load: { defaults().object(forKey: key) as? Bool ?? true },
      save: { defaults().set($0, forKey: key) }
    )
  }

  public static let liveValue = stored()

  public static let testValue = SoundPreference(load: { true }, save: { _ in })
}
