import CloudKit
import Dependencies
import Foundation
import SQLiteData

extension Friend: QueryBindable {}
extension Profile.Accent: QueryBindable {}
extension Profile.Theme: QueryBindable {}

@Table("profiles")
struct ProfileRecord: Equatable, Identifiable {
  static let only = "profile"

  let id: String
  var childName = ""
  var startingFriend = Friend.bunny
  var accent = Profile.Accent.canadian
  var voiceID: String?
  var theme = Profile.Theme.device
  var soundButtons = false
}

@Table("progress")
struct ProgressRecord: Equatable, Identifiable {
  static let only = "progress"

  let id: String
  var stars = 0
  @Column(as: Journey.JSONRepresentation.self)
  var journey = Journey()
  @Column(as: [Friend: Basket].JSONRepresentation.self)
  var baskets: [Friend: Basket] = [:]
  @Column(as: [Friend: [Slot: String]].JSONRepresentation.self)
  var outfits: [Friend: [Slot: String]] = [:]
}

@Table("storyProgress")
struct StoryProgressRecord: Equatable, Identifiable {
  let id: String
  var completedSentences = 0
  var wordsRead = 0
}

extension ProfileRecord {
  init(_ profile: Profile) {
    self.init(
      id: Self.only,
      childName: profile.childName,
      startingFriend: profile.startingFriend,
      accent: profile.accent,
      voiceID: profile.voiceID,
      theme: profile.theme,
      soundButtons: profile.soundButtons
    )
  }

  var profile: Profile {
    Profile(
      childName: childName,
      startingFriend: startingFriend,
      accent: accent,
      voiceID: voiceID,
      theme: theme,
      soundButtons: soundButtons
    )
  }
}

extension ProgressRecord {
  init(_ progress: Progress) {
    self.init(
      id: Self.only,
      stars: progress.stars,
      journey: progress.journey,
      baskets: progress.baskets,
      outfits: progress.outfits
    )
  }
}

public enum HopTalesDatabase {
  public static func migrator(importingFrom legacy: URL? = nil) -> DatabaseMigrator {
    var migrator = DatabaseMigrator()
    migrator.registerMigration("Create profiles, progress and storyProgress") { db in
      try #sql(
        """
        CREATE TABLE "profiles" (
          "id" TEXT PRIMARY KEY NOT NULL,
          "childName" TEXT NOT NULL DEFAULT '',
          "startingFriend" TEXT NOT NULL DEFAULT 'bunny',
          "accent" TEXT NOT NULL DEFAULT 'en-CA',
          "voiceID" TEXT,
          "theme" TEXT NOT NULL DEFAULT 'device',
          "soundButtons" INTEGER NOT NULL DEFAULT 0
        ) STRICT
        """
      )
      .execute(db)
      try #sql(
        """
        CREATE TABLE "progress" (
          "id" TEXT PRIMARY KEY NOT NULL,
          "stars" INTEGER NOT NULL DEFAULT 0,
          "journey" TEXT NOT NULL,
          "baskets" TEXT NOT NULL,
          "outfits" TEXT NOT NULL
        ) STRICT
        """
      )
      .execute(db)
      try #sql(
        """
        CREATE TABLE "storyProgress" (
          "id" TEXT PRIMARY KEY NOT NULL,
          "completedSentences" INTEGER NOT NULL DEFAULT 0,
          "wordsRead" INTEGER NOT NULL DEFAULT 0
        ) STRICT
        """
      )
      .execute(db)
    }
    migrator.registerMigration("Import progress.json and profile.json") { db in
      guard let legacy else { return }
      try importFiles(from: legacy, into: db)
    }
    return migrator
  }

  static func importFiles(from legacy: URL, into db: Database) throws {
    let profileURL = legacy.appending(path: "profile.json")
    if let profile = ProfileStore.read(Profile.self, from: profileURL) {
      try ProfileRecord.upsert { ProfileRecord(profile) }.execute(db)
    }
    let progressURL = legacy.appending(path: "progress.json")
    if let progress = ProfileStore.read(Progress.self, from: progressURL) {
      try ProgressStore.write(progress, over: nil, in: db)
    }
  }
}

extension DependencyValues {
  public mutating func bootstrapDatabase() throws {
    let database = try SQLiteData.defaultDatabase()
    let legacy = context == .live ? ProgressStore.applicationSupport : nil
    try HopTalesDatabase.migrator(importingFrom: legacy).migrate(database)
    defaultDatabase = database
    guard context == .live else { return }
    defaultSyncEngine = try SyncEngine(
      for: database,
      tables: ProfileRecord.self,
      ProgressRecord.self,
      StoryProgressRecord.self,
      containerIdentifier: CloudSync.containerIdentifier,
      defaultZone: CloudSync.zone,
      startImmediately: CloudSync.isEnabledOnThisDevice
    )
  }
}
