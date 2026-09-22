import CoreGraphics
import Foundation
import SnapshotTesting
import Testing

/// The screen every reference image is sized for — iPhone 18 Pro, in points.
let snapshotReferenceSize = CGSize(width: 390, height: 844)

/// The directory the reference images for `file` are read from.
///
/// `assertSnapshot` derives this from `#filePath`, the path the test file was compiled at. On
/// Xcode Cloud nothing is at that path when the tests run, so every reference looked missing and
/// CI recorded fresh images instead of comparing against ours. `Package.swift` therefore copies
/// `__Snapshots__` into the test bundle as well, and we fall back to it whenever the checked-out
/// directory holds no references — which keeps re-recording on a developer's machine writing to
/// the source tree, where it belongs.
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

/// `assertSnapshot`, but reading references from ``snapshotDirectory(file:)`` and reporting the
/// mismatch as a Swift Testing issue at the call site.
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
  Issue.record(
    Comment(rawValue: failure),
    sourceLocation: SourceLocation(
      fileID: "\(fileID)",
      filePath: "\(file)",
      line: Int(line),
      column: Int(column)
    )
  )
}
