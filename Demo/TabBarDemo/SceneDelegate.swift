//  Created by Sun on 2026/3/30.

import TabBar
import UIKit

enum DemoThemeMode: String, CaseIterable {
    case system
    case light
    case dark

    var title: String {
        switch self {
        case .system:
            return "跟随系统"
        case .light:
            return "亮"
        case .dark:
            return "暗"
        }
    }

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

final class DemoThemeController {
    static let shared = DemoThemeController()
    static let didChangeNotification = Notification.Name("DemoThemeController.didChange")

    private static let storageKey = "TabBarDemo.themeMode"
    private let userDefaults: UserDefaults

    private(set) var mode: DemoThemeMode

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        mode = DemoThemeMode(rawValue: userDefaults.string(forKey: Self.storageKey) ?? "") ?? .system
    }

    var interfaceStyle: UIUserInterfaceStyle {
        mode.interfaceStyle
    }

    func setMode(_ mode: DemoThemeMode) {
        guard self.mode != mode else {
            return
        }
        self.mode = mode
        userDefaults.set(mode.rawValue, forKey: Self.storageKey)
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }

    func tabBarTheme(for traits: UITraitCollection) -> TabBarStyle {
        switch resolvedStyle(for: traits) {
        case .dark:
            return .dark
        default:
            return .default
        }
    }

    private func resolvedStyle(for traits: UITraitCollection) -> UIUserInterfaceStyle {
        switch mode {
        case .system:
            return traits.userInterfaceStyle == .dark ? .dark : .light
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private weak var tabBarController: DemoTabBarController?
    private var themeObserver: NSObjectProtocol?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        let tabBar = DemoTabBarController()
        tabBarController = tabBar
        let nav = UINavigationController(rootViewController: tabBar)
        nav.isNavigationBarHidden = true
        nav.delegate = tabBar
        window?.rootViewController = nav

        themeObserver = NotificationCenter.default.addObserver(
            forName: DemoThemeController.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.applyTheme()
        }

        applyTheme()
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_: UIScene) {
        if let themeObserver {
            NotificationCenter.default.removeObserver(themeObserver)
            self.themeObserver = nil
        }
    }

    private func applyTheme() {
        guard let window else {
            return
        }
        window.overrideUserInterfaceStyle = DemoThemeController.shared.interfaceStyle
        tabBarController?.applyStyle(DemoThemeController.shared.tabBarTheme(for: window.traitCollection))
    }
}
