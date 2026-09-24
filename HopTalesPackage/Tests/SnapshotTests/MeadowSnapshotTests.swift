import Content
import SnapshotTesting
import SwiftUI
import Testing

@testable import World

@MainActor
@Suite(.snapshots(record: .missing, diffTool: .ksdiff))
struct MeadowSnapshotTests {
  nonisolated static let moods: [Mood] = [
    Mood(sky: .day, weather: .clear),
    Mood(sky: .golden, weather: .clouds),
    Mood(sky: .day, weather: .storm),
    Mood(sky: .day, weather: .rain),
    Mood(sky: .dusk, weather: .clear),
    Mood(sky: .night, weather: .clear)
  ]

  @Test(arguments: moods)
  func theMeadowInEveryMood(mood: Mood) {
    let size = CGSize(width: 390, height: 844)
    expectSnapshot(
      of: Image(uiImage: MeadowPostcard.image(mood: mood, size: size, progress: 600))
        .resizable()
        .frame(width: size.width, height: size.height),
      as: .image(perceptualPrecision: snapshotPerceptualPrecision, layout: .sizeThatFits),
      named: "\(mood.sky.rawValue)-\(mood.weather.rawValue)"
    )
  }
}
