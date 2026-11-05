import Clocks
import Dependencies
import DependenciesTestSupport
import Foundation
import Testing

extension Trait where Self == _DependenciesTrait {
  static var steady: Self {
    .dependencies {
      var calendar = Calendar(identifier: .gregorian)
      calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
      $0.calendar = calendar
      $0.continuousClock = TestClock()
      $0.date = .constant(Date(timeIntervalSince1970: 1_800_000_000))
      $0.locale = Locale(identifier: "en_US")
    }
  }
}
