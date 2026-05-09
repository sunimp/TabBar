//
//  DemoTabBarController.swift
//  TabBarDemo
//
//  Created by Sun on 2026/4/20.
//

import GradientBlur
import TabBar
import UIKit

protocol TabBarReselectHandling: AnyObject {
    func handleTabBarReselect()
}

protocol TabBarDoubleTapHandling: AnyObject {
    func handleTabBarDoubleTap()
}

final class DemoTabBarController: TabBarController, UINavigationControllerDelegate, TabBarControllerDelegate {
    private let gradientBlurView: GradientBlurView = .init(
        direction: .bottomToTop,
        maxBlurRadius: 6,
        blurScale: 0.5,
        isTransparent: false
    )

    init() {
        super.init(style: .default)
        delegate = self

        let chats = ChatListViewController()
        let contacts = ContactsViewController()
        let settings = SettingsViewController()

        let items: [TabBarItem] = [
            TabBarItem(
                title: "聊天",
                badgeValue: "3",
                animation: TabBarItemAnimation(name: "TabChats")
            ),
            TabBarItem(
                title: "",
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
        // 插入到 contentView 和 tabBar 之间
        view.insertSubview(gradientBlurView, belowSubview: tabBar)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutGradientBlur()
    }

    func applyStyle(_ style: TabBarStyle) {
        self.style = style
        updateGradientTint()
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let isRoot = viewController === self
        navigationController.setNavigationBarHidden(isRoot, animated: animated)

        let isDetail = viewController is ChatDetailViewController
        setTabBarEnabled(!isDetail, animated: animated)
    }

    func tabBarController(_: TabBarController, didReselect viewController: UIViewController, at _: Int) {
        (viewController as? TabBarReselectHandling)?.handleTabBarReselect()
    }

    func tabBarController(_: TabBarController, didDoubleTap viewController: UIViewController, at _: Int) {
        (viewController as? TabBarDoubleTapHandling)?.handleTabBarDoubleTap()
    }

    // MARK: - Gradient Blur

    private func layoutGradientBlur() {
        let bounds = view.bounds
        let edgeEffectHeight = tabBarTotalHeight
        guard edgeEffectHeight > 0 else { return }
        let edgeEffectFrame = CGRect(
            x: 0.0,
            y: bounds.height - edgeEffectHeight,
            width: bounds.width,
            height: edgeEffectHeight
        )
        // 渐变过渡段最多 40pt，剩余部分作为底部 solid 区域
        let gradientSize = min(edgeEffectHeight, 40.0)
        let solidSize = max(0.0, edgeEffectHeight - gradientSize)
        gradientBlurView.frame = edgeEffectFrame
        gradientBlurView.update(
            size: edgeEffectFrame.size,
            constantHeight: gradientSize + solidSize,
            startOffset: solidSize
        )
        updateGradientTint()
    }

    private func updateGradientTint() {
        let tintColor: UIColor = style.isDark
            ? UIColor(white: 0.0, alpha: 1.0)
            : UIColor(white: 1.0, alpha: 1.0)
        let tintAlpha: CGFloat = style.isDark ? 0.4 : 0.6
        gradientBlurView.updateTint(color: tintColor, alpha: tintAlpha)
    }
}
