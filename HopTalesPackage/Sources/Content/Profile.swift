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

public struct ProfileDraft: Codable, Hashable, Sendable {
  public var childName: String
  public var startingStoryID: String?
  public var accent: Profile.Accent?
  public var voiceID: String?
  public var step: Int

  public init(
    childName: String = "",
    startingStoryID: String? = nil,
    accent: Profile.Accent? = nil,
    voiceID: String? = nil,
    step: Int
  ) {
    self.childName = childName
    self.startingStoryID = startingStoryID
    self.accent = accent
    self.voiceID = voiceID
    self.step = step
  }
}

public struct ProfileStore: Sendable {
  public var load: @Sendable () -> Profile?
  public var save: @Sendable (Profile) -> Void
  public var loadDraft: @Sendable () -> ProfileDraft?
  public var saveDraft: @Sendable (ProfileDraft?) -> Void
  public var erase: @Sendable () -> Void

  public init(
    load: @escaping @Sendable () -> Profile?,
    save: @escaping @Sendable (Profile) -> Void,
    loadDraft: @escaping @Sendable () -> ProfileDraft? = { nil },
    saveDraft: @escaping @Sendable (ProfileDraft?) -> Void = { _ in },
    erase: @escaping @Sendable () -> Void = {}
  ) {
    self.load = load
    self.save = save
    self.loadDraft = loadDraft
    self.saveDraft = saveDraft
    self.erase = erase
  }
}

extension ProfileStore: DependencyKey {
  public static let fileName = "profile.json"
  public static let draftFileName = "profile-draft.json"

  public static func file(in directory: URL) -> ProfileStore {
    let url = directory.appending(path: fileName)
    let draftURL = directory.appending(path: draftFileName)
    return ProfileStore(
      load: { read(Profile.self, from: url) },
      save: { profile in
        write(profile, to: url, in: directory)
        try? FileManager.default.removeItem(at: draftURL)
      },
      loadDraft: { read(ProfileDraft.self, from: draftURL) },
      saveDraft: { draft in
        guard let draft else {
          try? FileManager.default.removeItem(at: draftURL)
          return
        }
        write(draft, to: draftURL, in: directory)
      },
      erase: {
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.removeItem(at: draftURL)
      }
    )
  }

  static func read<Value: Decodable>(_ type: Value.Type, from url: URL) -> Value? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder().decode(type, from: data)
  }

  static func write(_ value: some Encodable, to url: URL, in directory: URL) {
    guard let data = try? JSONEncoder().encode(value) else { return }
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try? data.write(to: url, options: .atomic)
  }

  public static let liveValue = file(in: ProgressStore.applicationSupport)

  public static let testValue = ProfileStore(load: { Profile() }, save: { _ in })

  public static let firstRun = ProfileStore(load: { nil }, save: { _ in })
}
