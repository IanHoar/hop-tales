import Dependencies
import Foundation

public struct StrictnessPreference: Sendable {
  public var load: @Sendable () -> WordMatcher.Strictness
  public var save: @Sendable (WordMatcher.Strictness) -> Void

  public init(
    load: @escaping @Sendable () -> WordMatcher.Strictness,
    save: @escaping @Sendable (WordMatcher.Strictness) -> Void
  ) {
    self.load = load
    self.save = save
  }
}

extension StrictnessPreference: DependencyKey {
  public static let key = "matching-strictness"

  public static func stored(in suiteName: String? = nil) -> StrictnessPreference {
    @Sendable func defaults() -> UserDefaults {
      suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }
    return StrictnessPreference(
      load: {
        let stored = defaults().string(forKey: key)
        return stored.flatMap(WordMatcher.Strictness.init(rawValue:)) ?? .gentle
      },
      save: { defaults().set($0.rawValue, forKey: key) }
    )
  }

  public static let liveValue = stored()

  public static let testValue = StrictnessPreference(
    load: { .gentle },
    save: { _ in }
  )
}
