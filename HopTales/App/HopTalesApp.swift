import AppFeature
import ComposableArchitecture2
import SwiftUI
import UIKit

@main
struct HopTalesApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  static let store = Store(initialState: Root.State()) {
    Root()
  }

  init() {
    UIWindow.appearance().backgroundColor = UIColor(
      red: 0x1E / 255, green: 0x2A / 255, blue: 0x4E / 255, alpha: 1
    )
  }

  var body: some Scene {
    WindowGroup {
      RootScreen(store: Self.store)
    }
  }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    if connectingSceneSession.role == .windowExternalDisplayNonInteractive {
      configuration.delegateClass = ExternalDisplaySceneDelegate.self
    }
    return configuration
  }
}

final class ExternalDisplaySceneDelegate: NSObject, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }
    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = UIHostingController(rootView: TVScreen(store: HopTalesApp.store))
    window.isHidden = false
    self.window = window
  }
}
