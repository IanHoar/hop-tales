import DesignSystem
import Foundation
import SnapshotTesting
import SwiftUI
import Testing
import UIKit

let snapshotRuntime = "27.0"
let snapshotRuntimeBuild = "24A434"

func snapshotDirectory(file: StaticString = #filePath) -> String {
  let file = URL(fileURLWithPath: "\(file)")
  let suffix = "__Snapshots__/\(file.deletingPathExtension().lastPathComponent)"
  let source = file.deletingLastPathComponent().appendingPathComponent(suffix)

  func holdsReferences(_ url: URL) -> Bool {
    let contents = try? FileManager.default.contentsOfDirectory(atPath: url.path)
    return contents?.contains { $0.hasSuffix(".png") } ?? false
  }

  if holdsReferences(source) { return source.path }
  let bundled = Bundle.module.resourceURL?.appendingPathComponent(suffix)
  if let bundled, holdsReferences(bundled) { return bundled.path }
  return source.path
}

@MainActor
func expectSnapshot<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as snapshotting: Snapshotting<Value, Format>,
  named name: String? = nil,
  fileID: StaticString = #fileID,
  file: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  let location = SourceLocation(
    fileID: "\(fileID)",
    filePath: "\(file)",
    line: Int(line),
    column: Int(column)
  )
  let running = UIDevice.current.systemVersion
  let build = ProcessInfo.processInfo.environment["SIMULATOR_RUNTIME_BUILD_VERSION"] ?? "unknown"
  guard running == snapshotRuntime, build == snapshotRuntimeBuild else {
    let message = "Snapshot references were recorded on iOS \(snapshotRuntime) "
      + "(\(snapshotRuntimeBuild)), but this simulator runs iOS \(running) (\(build)). Test on "
      + "iPhone 18 Pro with iOS \(snapshotRuntime) (\(snapshotRuntimeBuild)), as "
      + "docs/xcode-cloud.md pins it, or re-record every reference on the new runtime."
    Issue.record(Comment(rawValue: message), sourceLocation: location)
    return
  }
  guard
    let failure = verifySnapshot(
      of: try value(),
      as: snapshotting,
      named: name,
      snapshotDirectory: snapshotDirectory(file: file),
      fileID: fileID,
      file: file,
      testName: testName,
      line: line,
      column: column
    )
  else { return }
  Issue.record(Comment(rawValue: failure), sourceLocation: location)
}

@MainActor
func expectSnapshot(
  of view: some View,
  scheme: ColorScheme,
  fileID: StaticString = #fileID,
  file: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line,
  column: UInt = #column
) {
  expectSnapshot(
    of: view.environment(\.colorScheme, scheme).environment(\.freezesMotion, true),
    as: .image(
      layout: .sizeThatFits,
      traits: UITraitCollection(userInterfaceStyle: scheme == .dark ? .dark : .light)
    ),
    named: "\(scheme)",
    fileID: fileID,
    file: file,
    testName: testName,
    line: line,
    column: column
  )
}
