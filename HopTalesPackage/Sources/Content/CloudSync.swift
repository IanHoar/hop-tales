import CloudKit
import Dependencies
import Foundation
import SQLiteData

public struct CloudSync: Sendable {
  public enum Account: Equatable, Sendable {
    case available
    case signedOut
    case unavailable
  }

  public var account: @Sendable () async -> Account
  public var isEnabled: @Sendable () -> Bool
  public var setEnabled: @Sendable (Bool) async -> Void
  public var catchUp: @Sendable () async -> Void
  public var deleteCloudCopy: @Sendable () async throws -> Void

  public init(
    account: @escaping @Sendable () async -> Account,
    isEnabled: @escaping @Sendable () -> Bool,
    setEnabled: @escaping @Sendable (Bool) async -> Void,
    catchUp: @escaping @Sendable () async -> Void = {},
    deleteCloudCopy: @escaping @Sendable () async throws -> Void = {}
  ) {
    self.account = account
    self.isEnabled = isEnabled
    self.setEnabled = setEnabled
    self.catchUp = catchUp
    self.deleteCloudCopy = deleteCloudCopy
  }
}

extension CloudSync: DependencyKey {
  public static let containerIdentifier = "iCloud.com.hoptales.ios"
  static let zone = CKRecordZone(zoneName: "HopTales")
  static let preferenceKey = "cloudSyncEnabled"

  public static var isEnabledOnThisDevice: Bool {
    UserDefaults.standard.bool(forKey: preferenceKey)
  }

  static var container: CKContainer { CKContainer(identifier: containerIdentifier) }

  public static let liveValue = CloudSync(
    account: {
      switch try? await container.accountStatus() {
      case .available: .available
      case .noAccount: .signedOut
      default: .unavailable
      }
    },
    isEnabled: { isEnabledOnThisDevice },
    setEnabled: { isOn in
      @Dependency(\.defaultSyncEngine) var syncEngine
      UserDefaults.standard.set(isOn, forKey: preferenceKey)
      guard isOn else {
        syncEngine.stop()
        return
      }
      await withErrorReporting { try await syncEngine.start() }
    },
    catchUp: {
      @Dependency(\.defaultSyncEngine) var syncEngine
      guard syncEngine.isRunning else { return }
      try? await syncEngine.fetchChanges()
    },
    deleteCloudCopy: {
      @Dependency(\.defaultSyncEngine) var syncEngine
      @Dependency(\.defaultDatabase) var database
      UserDefaults.standard.set(false, forKey: preferenceKey)
      syncEngine.stop()
      let kept = try await database.read { db in
        try KeptRecords(
          profiles: ProfileRecord.fetchAll(db),
          progress: ProgressRecord.fetchAll(db),
          stories: StoryProgressRecord.fetchAll(db)
        )
      }
      _ = try await container.privateCloudDatabase.deleteRecordZone(withID: zone.zoneID)
      try await syncEngine.deleteLocalData()
      syncEngine.stop()
      try await database.write { db in try kept.restore(in: db) }
    }
  )

  public static let testValue = CloudSync(
    account: { .available },
    isEnabled: { false },
    setEnabled: { _ in }
  )
}

private struct KeptRecords: Sendable {
  var profiles: [ProfileRecord]
  var progress: [ProgressRecord]
  var stories: [StoryProgressRecord]

  func restore(in db: Database) throws {
    for record in profiles { try ProfileRecord.upsert { record }.execute(db) }
    for record in progress { try ProgressRecord.upsert { record }.execute(db) }
    for record in stories { try StoryProgressRecord.upsert { record }.execute(db) }
  }
}
