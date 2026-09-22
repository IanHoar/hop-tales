import Foundation

/// The stories bundled with the app, loaded from `Resources/stories.json`.
public enum StoryLibrary {
  public static let all: [Story] = {
    guard let url = Bundle.module.url(forResource: "stories", withExtension: "json") else {
      assertionFailure("stories.json is missing from the Content resource bundle")
      return []
    }
    do {
      return try JSONDecoder().decode([Story].self, from: Data(contentsOf: url))
    } catch {
      assertionFailure("stories.json could not be decoded: \(error)")
      return []
    }
  }()

  public static subscript(id: Story.ID) -> Story? {
    all.first { $0.id == id }
  }
}
