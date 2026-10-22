import Content
import Dependencies
import IssueReporting

extension Root {
  public static func bootstrap() {
    prepareDependencies {
      do {
        try $0.bootstrapDatabase()
      } catch {
        reportIssue(error)
      }
    }
    @Dependency(PurchasesClient.self) var purchases
    purchases.start()
  }
}
