//
//  DemoTabBarController.swift
//  TabBarDemo
//
//  Created by Sun on 2026/4/20.
//

import TabBar
import UIKit

protocol TabBarReselectHandling: AnyObject {
    func handleTabBarReselect()
}

protocol TabBarDoubleTapHandling: AnyObject {
    func handleTabBarDoubleTap()
}

final class DemoTabBarController: TabBarController, UINavigationControllerDelegate, TabBarControllerDelegate {
    init() {
        super.init(style: .default)
        delegate = self

        let chats = ChatSplitViewController()
        let contacts = ContactsViewController()
        let settings = SettingsViewController()

        let items: [TabBarItem] = [
            TabBarItem(
                title: "聊天",
                badgeValue: "3",
                animation: TabBarItemAnimation(name: "TabChats")
            ),
            TabBarItem(
                title: "联系人",
                animation: TabBarItemAnimation(name: "TabContacts")
            ),
            TabBarItem(
                title: "设置",
                animation: TabBarItemAnimation(name: "TabSettings")
            ),
        ]

        setViewControllers([chats, contacts, settings], items: items, selectedIndex: 0)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (controller: DemoTabBarController, _: UITraitCollection) in
                controller.synchronizeTheme()
            }
        }
        updateNavigationTitle()
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        synchronizeTheme()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17.0), previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            synchronizeTheme()
        }
    }

    func synchronizeTheme() {
        let traits = view.window?.traitCollection ?? traitCollection
        applyStyle(DemoThemeController.shared.tabBarTheme(for: traits))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    func applyStyle(_ style: TabBarStyle) {
        guard self.style != style else { return }
        self.style = style
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let usesSplitNavigation = viewController === self && selectedViewController is ChatSplitViewController
        navigationController.setNavigationBarHidden(usesSplitNavigation, animated: animated)
        navigationItem.title = viewController === self ? selectedViewController?.title : viewController.title

        let isDetail = viewController is ChatDetailViewController
        setTabBarEnabled(!isDetail, animated: animated)
    }

    func tabBarController(_: TabBarController, didSelect _: UIViewController, at _: Int) {
        updateNavigationTitle()
    }

    private func updateNavigationTitle() {
        selectedViewController?.loadViewIfNeeded()
        navigationItem.title = selectedViewController?.title
    }

    func tabBarController(_: TabBarController, didReselect viewController: UIViewController, at _: Int) {
        (viewController as? TabBarReselectHandling)?.handleTabBarReselect()
    }

    func tabBarController(_: TabBarController, didDoubleTap viewController: UIViewController, at _: Int) {
        (viewController as? TabBarDoubleTapHandling)?.handleTabBarDoubleTap()
    }

}
