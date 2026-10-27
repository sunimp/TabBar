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

/// 「列表 + 详情」tab 容器，聊天与设置共用。
///
/// - 横纵 size class 均为 regular（iPhone Duo 展开内屏、iPad）：双栏，隐藏外层导航栏，各栏使用自身系统导航栏，
///   详情替换 secondary 栏。
/// - 其它情况（普通 iPhone、Pro Max 横屏、Duo 外屏）：折叠为单栏，使用外层系统导航栏，
///   详情 push 到外层导航，TabBar 随列表页一起左移。
///
/// 按 size class 而非设备型号判断，符合 HIG 建议。
class ListDetailSplitViewController: UIViewController, UISplitViewControllerDelegate {
    private let listViewController: UIViewController
    private let initialDetailViewController: UIViewController
    private let splitController = UISplitViewController(style: .doubleColumn)

    init(list: UIViewController, initialDetail: UIViewController) {
        listViewController = list
        initialDetailViewController = initialDetail
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 是否处于双栏展开状态（此时使用各栏自身的导航栏）。
    var showsColumnNavigationBars: Bool {
        !splitController.isCollapsed
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        splitController.delegate = self
        splitController.preferredDisplayMode = .oneBesideSecondary
        splitController.setViewController(UINavigationController(rootViewController: listViewController), for: .primary)
        splitController.setViewController(UINavigationController(rootViewController: initialDetailViewController), for: .secondary)

        addChild(splitController)
        splitController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(splitController.view)
        NSLayoutConstraint.activate([
            splitController.view.topAnchor.constraint(equalTo: view.topAnchor),
            splitController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            splitController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            splitController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        splitController.didMove(toParent: self)

        updateSplitExpansion()
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitVerticalSizeClass.self]) { (controller: ListDetailSplitViewController, _: UITraitCollection) in
                controller.updateSplitExpansion()
            }
        }

        // 标题在列表 viewDidLoad 中设置，需先加载列表。
        listViewController.loadViewIfNeeded()
        title = listViewController.title
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        updateNavigationBars()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17.0) {
            updateSplitExpansion()
        }
    }

    /// 转发列表的滚动视图，供外层导航栏大标题跟随滚动。
    override func contentScrollView(for edge: NSDirectionalRectEdge) -> UIScrollView? {
        listViewController.contentScrollView(for: edge)
    }

    /// 展示详情：双栏时替换 secondary 栏，单栏时 push 到外层导航。
    func showDetail(_ detail: UIViewController) {
        if splitController.isCollapsed {
            navigationController?.pushViewController(detail, animated: true)
        } else {
            splitController.setViewController(UINavigationController(rootViewController: detail), for: .secondary)
        }
    }

    // MARK: - UISplitViewControllerDelegate

    func splitViewControllerDidCollapse(_: UISplitViewController) {
        updateNavigationBars()
    }

    func splitViewControllerDidExpand(_: UISplitViewController) {
        updateNavigationBars()
    }

    /// 折叠为单栏时显示列表而非默认详情；column 风格 split 不调用 `collapseSecondary:onto:`。
    func splitViewController(_: UISplitViewController, topColumnForCollapsingToProposedTopColumn _: UISplitViewController.Column) -> UISplitViewController.Column {
        .primary
    }

    // MARK: - Private

    /// 仅在横纵均为 regular 时允许展开；vertical compact（如 Pro Max 横屏）强制 compact 以折叠为单栏。
    private func updateSplitExpansion() {
        let allowsExpansion = traitCollection.verticalSizeClass != .compact
        if #available(iOS 17.0, *) {
            if allowsExpansion {
                splitController.traitOverrides.remove(UITraitHorizontalSizeClass.self)
            } else {
                splitController.traitOverrides.horizontalSizeClass = .compact
            }
        } else {
            setOverrideTraitCollection(allowsExpansion ? nil : UITraitCollection(horizontalSizeClass: .compact), forChild: splitController)
        }
    }

    /// 单栏时隐藏栏内导航栏、改用外层系统导航栏；双栏时反之。
    private func updateNavigationBars() {
        listViewController.navigationController?.setNavigationBarHidden(splitController.isCollapsed, animated: false)
        (parent as? DemoTabBarController)?.updateNavigationBarVisibility()
    }
}

final class DemoTabBarController: TabBarController, UINavigationControllerDelegate, TabBarControllerDelegate {
    init() {
        super.init(style: .default)
        delegate = self

        let chats = ChatSplitViewController()
        let contacts = ContactsViewController()
        let settings = SettingsSplitViewController()

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
        navigationController.setNavigationBarHidden(viewController === self && showsColumnNavigationBars, animated: animated)
        navigationItem.title = viewController === self ? selectedViewController?.title : viewController.title

        let isDetail = viewController is ChatDetailViewController
        setTabBarEnabled(!isDetail, animated: animated)
    }

    func tabBarController(_: TabBarController, didSelect _: UIViewController, at _: Int) {
        updateNavigationTitle()
        updateNavigationBarVisibility()
    }

    /// 当前 tab 为双栏 split 时隐藏外层导航栏，避免与栏内导航栏重复。
    func updateNavigationBarVisibility() {
        guard navigationController?.topViewController === self else { return }
        navigationController?.setNavigationBarHidden(showsColumnNavigationBars, animated: false)
    }

    private var showsColumnNavigationBars: Bool {
        (selectedViewController as? ListDetailSplitViewController)?.showsColumnNavigationBars == true
    }

    private func updateNavigationTitle() {
        selectedViewController?.loadViewIfNeeded()
        navigationItem.title = selectedViewController?.title
        // 外层导航栏大标题跟随当前 tab 的列表滚动（下拉拉伸、上滑收起）。
        setContentScrollView(selectedViewController?.contentScrollView(for: .top), for: .top)
    }

    func tabBarController(_: TabBarController, didReselect viewController: UIViewController, at _: Int) {
        (viewController as? TabBarReselectHandling)?.handleTabBarReselect()
    }

    func tabBarController(_: TabBarController, didDoubleTap viewController: UIViewController, at _: Int) {
        (viewController as? TabBarDoubleTapHandling)?.handleTabBarDoubleTap()
    }

}
