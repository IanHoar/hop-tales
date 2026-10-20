import Content
import Testing

struct PaintedLooks: SuiteTrait, TestScoping {
  func provideScope(
    for test: Test, testCase: Test.Case?, performing function: () async throws -> Void
  ) async throws {
    let painted = WardrobeLibrary.wearable.mapValues(Set.init)
    try await WardrobeLibrary.$painted.withValue(painted, operation: function)
  }
}

extension Trait where Self == PaintedLooks {
  static var everyLookPainted: Self { PaintedLooks() }
}
