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
      case .canadian: "Canadian"
      case .american: "American"
      case .british: "British"
      case .australian: "Australian"
      }
    }

    public var locale: Locale { Locale(identifier: rawValue) }
  }

  public enum Theme: String, Codable, CaseIterable, Hashable, Sendable {
    case device
    case light
    case dark

    public var name: String {
      switch self {
      case .device: "Match device"
      case .light: "Light"
      case .dark: "Dark"
      }
    }
  }

  public var childName: String
  public var startingFriend: Friend
  public var accent: Accent
  public var voiceID: String?
  public var theme: Theme
  public var soundButtons: Bool

  public init(
    childName: String = "",
    startingFriend: Friend = .bunny,
    accent: Accent = .canadian,
    voiceID: String? = nil,
    theme: Theme = .device,
    soundButtons: Bool = false
  ) {
    self.childName = childName
    self.startingFriend = startingFriend
    self.accent = accent
    self.voiceID = voiceID
    self.theme = theme
    self.soundButtons = soundButtons
  }

  public var startingStoryID: String { startingFriend.startingStoryID }

  enum CodingKeys: String, CodingKey {
    case childName
    case startingFriend
    case startingStoryID
    case accent
    case voiceID
    case theme
    case soundButtons
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    childName = try container.decode(String.self, forKey: .childName)
    accent = try container.decode(Accent.self, forKey: .accent)
    voiceID = try container.decodeIfPresent(String.self, forKey: .voiceID)
    theme = try container.decodeIfPresent(Theme.self, forKey: .theme) ?? .device
    soundButtons = try container.decodeIfPresent(Bool.self, forKey: .soundButtons) ?? false
    if let friend = try container.decodeIfPresent(Friend.self, forKey: .startingFriend) {
      startingFriend = friend
    } else {
      let story = try container.decodeIfPresent(String.self, forKey: .startingStoryID)
      startingFriend = story.map(Friend.init(startingStoryID:)) ?? .bunny
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(childName, forKey: .childName)
    try container.encode(startingFriend, forKey: .startingFriend)
    try container.encode(accent, forKey: .accent)
    try container.encodeIfPresent(voiceID, forKey: .voiceID)
    try container.encode(theme, forKey: .theme)
    try container.encode(soundButtons, forKey: .soundButtons)
  }
}

public struct ProfileDraft: Codable, Hashable, Sendable {
  public var childName: String
  public var startingFriend: Friend?
  public var accent: Profile.Accent?
  public var voiceID: String?
  public var soundButtons: Bool?
  public var step: Int

  public init(
    childName: String = "",
    startingFriend: Friend? = nil,
    accent: Profile.Accent? = nil,
    voiceID: String? = nil,
    soundButtons: Bool? = nil,
    step: Int
  ) {
    self.childName = childName
    self.startingFriend = startingFriend
    self.accent = accent
    self.voiceID = voiceID
    self.soundButtons = soundButtons
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
