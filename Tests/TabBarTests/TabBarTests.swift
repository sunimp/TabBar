//
//  TabBarTests.swift
//  TabBarTests
//
//  Created by Sun on 2026/3/30.
//

@testable import TabBar
import Testing
import UIKit

@Test func stylePresetsExposeDistinctLightAndDarkDefaults() {
    let light = TabBarStyle.default
    let dark = TabBarStyle.dark

    #expect(light.isDark == false)
    #expect(dark.isDark == true)
    #expect(light.backgroundColor != dark.backgroundColor)
    #expect(light.selectedIconColor != light.iconColor)
    #expect(dark.selectedIconColor != dark.iconColor)
}

@Test func styleEqualityReflectsConfigurationChanges() {
    let original = TabBarStyle.default
    var changed = TabBarStyle.default

    #expect(original == changed)

    changed.isDark = true

    #expect(original != changed)
}

@Test func tabBarItemAnimationUsesExpectedDefaults() {
    let animation = TabBarItemAnimation(name: "TabChats")

    #expect(animation.name == "TabChats")
    #expect(animation.offset == .zero)
    #expect(animation.playbackMode == .playOnce)
}

@Test func tabBarItemStoresExplicitConfiguration() {
    let image = UIImage(systemName: "message")
    let selectedImage = UIImage(systemName: "message.fill")
    let animation = TabBarItemAnimation(name: "TabChats", offset: CGPoint(x: 1.0, y: -2.0), playbackMode: .loop)

    let item = TabBarItem(
        id: "chats",
        title: "聊天",
        image: image,
        selectedImage: selectedImage,
        badgeValue: "9",
        animation: animation,
        accessibilityIdentifier: "tab.chats"
    )

    #expect(item.id == "chats")
    #expect(item.title == "聊天")
    #expect(item.image == image)
    #expect(item.selectedImage == selectedImage)
    #expect(item.badgeValue == "9")
    #expect(item.animation == animation)
    #expect(item.accessibilityIdentifier == "tab.chats")
}

@MainActor
@Test func tabBarViewClampsSelectedIndexToAvailableItems() {
    let tabBar = TabBarView(style: .default)
    tabBar.setItems(makeItems(count: 2), selectedIndex: 10)

    #expect(tabBar.selectedIndex == 1)

    tabBar.selectedIndex = -3

    #expect(tabBar.selectedIndex == 0)
}

@MainActor
@Test func tabBarViewEnabledStateControlsInteractionAndOpacity() {
    let tabBar = TabBarView(style: .default)

    tabBar.isTabBarEnabled = false

    #expect(tabBar.isUserInteractionEnabled == false)
    #expect(tabBar.alpha.isApproximatelyEqual(to: 0.7))

    tabBar.isTabBarEnabled = true

    #expect(tabBar.isUserInteractionEnabled == true)
    #expect(tabBar.alpha == 1.0)
}

@MainActor
@Test func tabBarViewContentHeightFallsBackToEstimatedHeightBeforeLayout() {
    let tabBar = TabBarView(style: .default)

    #expect(tabBar.contentHeight == 64.0)
    #expect(tabBar.intrinsicContentSize.height == 64.0)
}

@MainActor
@Test func controllerSetsInitialSelectionAndClampsOutOfRangeInitialIndex() {
    let controller = TabBarController(style: .default)
    let viewControllers = makeViewControllers(count: 2)

    controller.setViewControllers(viewControllers, items: makeItems(count: 2), selectedIndex: 99)

    #expect(controller.viewControllers == viewControllers)
    #expect(controller.selectedIndex == 1)
    #expect(controller.selectedViewController === viewControllers[1])
    #expect(viewControllers[1].parent === controller)
}

@MainActor
@Test func controllerSelectedIndexIgnoresInvalidValuesAndSwitchesValidValues() {
    let controller = TabBarController(style: .default)
    let viewControllers = makeViewControllers(count: 2)
    controller.setViewControllers(viewControllers, items: makeItems(count: 2), selectedIndex: 0)

    controller.selectedIndex = 9

    #expect(controller.selectedIndex == 0)
    #expect(controller.selectedViewController === viewControllers[0])

    controller.selectedIndex = 1

    #expect(controller.selectedViewController === viewControllers[1])
}

@MainActor
@Test func controllerReloadsItemsWithoutChangingSelectedIndex() {
    let controller = TabBarController(style: .default)
    controller.setViewControllers(makeViewControllers(count: 2), items: makeItems(count: 2), selectedIndex: 1)

    let updatedItems = [
        TabBarItem(id: "tab-0", title: "首页", badgeValue: "1"),
        TabBarItem(id: "tab-1", title: "设置", badgeValue: "2"),
    ]
    controller.reloadTabBarItems(updatedItems)

    #expect(controller.selectedIndex == 1)
    #expect(controller.tabBar.items == updatedItems)
}

@MainActor
@Test func controllerHiddenStateUpdatesTabBarVisibilityAndChildInsets() {
    let controller = TabBarController(style: .default)
    let child = UIViewController()
    attachToWindow(controller)
    controller.setViewControllers([child], items: makeItems(count: 1), selectedIndex: 0)
    controller.view.layoutIfNeeded()

    let visibleInset = child.additionalSafeAreaInsets.bottom

    controller.setTabBarHidden(true, animated: false)

    #expect(controller.tabBar.alpha == 0.0)
    #expect(controller.tabBarTotalHeight == 0.0)
    #expect(child.additionalSafeAreaInsets.bottom == 0.0)

    controller.setTabBarHidden(false, animated: false)

    #expect(controller.tabBar.alpha == 1.0)
    #expect(controller.tabBarTotalHeight > 0.0)
    #expect(child.additionalSafeAreaInsets.bottom == visibleInset)
}

@MainActor
@Test func controllerStyleSetterUpdatesTabBarAndBackground() {
    let controller = TabBarController(style: .default)
    controller.loadViewIfNeeded()

    controller.style = .dark

    #expect(controller.tabBar.style == .dark)
    #expect(controller.view.backgroundColor == TabBarStyle.dark.backgroundColor)
}

@MainActor
@Test func controllerForwardsSelectionDecisionToDelegate() {
    let controller = TabBarController(style: .default)
    let delegate = ControllerDelegateSpy()
    let viewControllers = makeViewControllers(count: 2)
    controller.delegate = delegate
    controller.setViewControllers(viewControllers, items: makeItems(count: 2), selectedIndex: 0)

    delegate.shouldSelectResult = false

    let shouldSelect = controller.tabBarView(controller.tabBar, shouldSelect: controller.tabBar.items[1], at: 1)

    #expect(shouldSelect == false)
    #expect(delegate.shouldSelectCalls == [1])
}

@MainActor
@Test func controllerSelectCallbackSwitchesSelectionAndNotifiesDelegate() {
    let controller = TabBarController(style: .default)
    let delegate = ControllerDelegateSpy()
    let viewControllers = makeViewControllers(count: 2)
    controller.delegate = delegate
    controller.setViewControllers(viewControllers, items: makeItems(count: 2), selectedIndex: 0)

    controller.tabBarView(controller.tabBar, didSelect: controller.tabBar.items[1], at: 1)

    #expect(controller.selectedViewController === viewControllers[1])
    #expect(delegate.didSelectCalls == [1])
}

@MainActor
@Test func controllerForwardsReselectAndDoubleTapCallbacks() {
    let controller = TabBarController(style: .default)
    let delegate = ControllerDelegateSpy()
    controller.delegate = delegate
    controller.setViewControllers(makeViewControllers(count: 2), items: makeItems(count: 2), selectedIndex: 1)

    controller.tabBarView(controller.tabBar, didReselect: controller.tabBar.items[1], at: 1)
    controller.tabBarView(controller.tabBar, didDoubleTap: controller.tabBar.items[1], at: 1)

    #expect(delegate.didReselectCalls == [1])
    #expect(delegate.didDoubleTapCalls == [1])
}

@MainActor
@Test func controllerEnabledStateDelegatesToTabBarView() {
    let controller = TabBarController(style: .default)

    controller.setTabBarEnabled(false, animated: false)

    #expect(controller.tabBar.isTabBarEnabled == false)
    #expect(controller.tabBar.isUserInteractionEnabled == false)
    #expect(controller.tabBar.alpha.isApproximatelyEqual(to: 0.7))

    controller.setTabBarEnabled(true, animated: false)

    #expect(controller.tabBar.isTabBarEnabled == true)
    #expect(controller.tabBar.isUserInteractionEnabled == true)
    #expect(controller.tabBar.alpha == 1.0)
}

@MainActor
@Test func controllerLaysOutVisibleTabBarAtExpectedBottomSpacing() {
    let controller = TabBarController(style: .default)
    attachToWindow(controller, frame: CGRect(x: 0, y: 0, width: 402, height: 874))
    controller.setViewControllers(makeViewControllers(count: 1), items: makeItems(count: 1), selectedIndex: 0)
    controller.view.layoutIfNeeded()

    let expectedBottomSpacing = expectedTabBarBottomSpacing(for: controller.view.safeAreaInsets.bottom)

    #expect(controller.tabBar.frame.height > 0.0)
    #expect(controller.tabBar.frame.maxY == controller.view.bounds.maxY - expectedBottomSpacing)
}

private func makeItems(count: Int) -> [TabBarItem] {
    (0 ..< count).map { index in
        TabBarItem(
            id: "tab-\(index)",
            title: "Tab \(index)",
            image: UIImage(systemName: "circle"),
            selectedImage: UIImage(systemName: "circle.fill")
        )
    }
}

@MainActor
private func makeViewControllers(count: Int) -> [UIViewController] {
    (0 ..< count).map { index in
        let viewController = UIViewController()
        viewController.view.accessibilityIdentifier = "view-controller-\(index)"
        return viewController
    }
}

@MainActor
@discardableResult
private func attachToWindow(
    _ controller: UIViewController,
    frame: CGRect = CGRect(x: 0, y: 0, width: 390, height: 844)
) -> UIWindow {
    let window = UIWindow(frame: frame)
    window.rootViewController = controller
    window.makeKeyAndVisible()
    controller.loadViewIfNeeded()
    controller.view.frame = window.bounds
    controller.view.setNeedsLayout()
    controller.view.layoutIfNeeded()
    return window
}

private func expectedTabBarBottomSpacing(for bottomSafeArea: CGFloat) -> CGFloat {
    let navigationHeight: CGFloat
    if #available(iOS 26.0, *) {
        navigationHeight = bottomSafeArea.isLessThanOrEqualTo(0.0) ? 0.0 : min(bottomSafeArea, 20.0)
    } else {
        navigationHeight = bottomSafeArea.isLessThanOrEqualTo(0.0) ? 0.0 : bottomSafeArea
    }
    return max(navigationHeight, 8.0)
}

private extension CGFloat {
    func isApproximatelyEqual(to value: CGFloat, tolerance: CGFloat = 0.001) -> Bool {
        abs(self - value) <= tolerance
    }
}

@MainActor
private final class ControllerDelegateSpy: @MainActor TabBarControllerDelegate {
    var shouldSelectResult = true
    var shouldSelectCalls: [Int] = []
    var didSelectCalls: [Int] = []
    var didReselectCalls: [Int] = []
    var didDoubleTapCalls: [Int] = []

    func tabBarController(_: TabBarController, shouldSelect _: UIViewController, at index: Int) -> Bool {
        shouldSelectCalls.append(index)
        return shouldSelectResult
    }

    func tabBarController(_: TabBarController, didSelect _: UIViewController, at index: Int) {
        didSelectCalls.append(index)
    }

    func tabBarController(_: TabBarController, didReselect _: UIViewController, at index: Int) {
        didReselectCalls.append(index)
    }

    func tabBarController(_: TabBarController, didDoubleTap _: UIViewController, at index: Int) {
        didDoubleTapCalls.append(index)
    }
}
