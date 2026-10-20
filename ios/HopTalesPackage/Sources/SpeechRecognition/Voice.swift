import Foundation

public struct Voice: Hashable, Identifiable, Sendable {
  public let id: String
  public let name: String
  public let language: String

  public init(id: String, name: String, language: String) {
    self.id = id
    self.name = name
    self.language = language
  }

  public var region: String {
    let code = Locale(identifier: language).region?.identifier
    return code.flatMap { Locale.current.localizedString(forRegionCode: $0) } ?? language
  }
}
