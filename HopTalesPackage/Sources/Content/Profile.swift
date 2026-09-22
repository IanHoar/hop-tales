import Dependencies
import Foundation

public struct Profile: Codable, Hashable, Sendable {
  public enum Accent: String, Codable, CaseIterable, Hashable, Sendable {
    case canadian = "en-CA"
    case american = "en-US"
    case british = "en-GB"
    case australian = "en-AU"

    public var name: String {
      switch self {
      case .canadian: "Canadian English"
      case .american: "American English"
      case .british: "British English"
      case .australian: "Australian English"
      }
    }

    public var locale: Locale { Locale(identifier: rawValue) }
  }

  public var childName: String
  public var startingStoryID: String
  public var accent: Accent
  public var voiceID: String?

  public init(
    childName: String = "",
    startingStoryID: String = StoryLibrary.all[0].id,
    accent: Accent = .canadian,
    voiceID: String? = nil
  ) {
    self.childName = childName
    self.startingStoryID = startingStoryID
    self.accent = accent
    self.voiceID = voiceID
  }
}

public struct ProfileStore: Sendable {
  public var load: @Sendable () -> Profile?
  public var save: @Sendable (Profile) -> Void

  public init(
    load: @escaping @Sendable () -> Profile?,
    save: @escaping @Sendable (Profile) -> Void
  ) {
    self.load = load
    self.save = save
  }
}

extension ProfileStore: DependencyKey {
  public static let fileName = "profile.json"

  public static func file(in directory: URL) -> ProfileStore {
    let url = directory.appending(path: fileName)
    return ProfileStore(
      load: {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Profile.self, from: data)
      },
      save: { profile in
        guard let data = try? JSONEncoder().encode(profile) else { return }
        try? FileManager.default.createDirectory(
          at: directory,
          withIntermediateDirectories: true
        )
        try? data.write(to: url, options: .atomic)
      }
    )
  }

  public static let liveValue = file(in: ProgressStore.applicationSupport)

  public static let testValue = ProfileStore(load: { Profile() }, save: { _ in })

  public static let firstRun = ProfileStore(load: { nil }, save: { _ in })
}
