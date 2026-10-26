//
//  TabBarController.swift
//  TabBar
//
//  Created by Sun on 2026/4/20.
//

import UIKit

// MARK: - TabBarControllerDelegate

/// TabBar 容器控制器的代理协议。
///
/// 提供 tab 选中、重选、双击等交互事件的回调。
public protocol TabBarControllerDelegate: AnyObject {
    /// 询问是否允许选中指定 tab。返回 `false` 可阻止切换。
    func tabBarController(_ controller: TabBarController, shouldSelect viewController: UIViewController, at index: Int) -> Bool
    /// 选中了一个新的 tab（与当前不同）。
    func tabBarController(_ controller: TabBarController, didSelect viewController: UIViewController, at index: Int)
    /// 重选了当前已选中的 tab（常用于滚动到顶部等操作）。
    func tabBarController(_ controller: TabBarController, didReselect viewController: UIViewController, at index: Int)
    /// 双击了某个 tab。
    func tabBarController(_ controller: TabBarController, didDoubleTap viewController: UIViewController, at index: Int)
}

public extension TabBarControllerDelegate {
    func tabBarController(_: TabBarController, shouldSelect _: UIViewController, at _: Int) -> Bool {
        true
    }

    func tabBarController(_: TabBarController, didSelect _: UIViewController, at _: Int) {}
    func tabBarController(_: TabBarController, didReselect _: UIViewController, at _: Int) {}
    func tabBarController(_: TabBarController, didDoubleTap _: UIViewController, at _: Int) {}
}

// MARK: - TabBarController

/// 自定义 TabBar 容器控制器。
///
/// 管理一组子控制器的切换，配合 `TabBarView` 实现浮动胶囊式底部导航栏。
/// 子控制器切换时使用 scale + opacity 过渡动画。
open class TabBarController: UIViewController, TabBarViewDelegate {
    /// 代理，接收 tab 交互事件。
    public weak var delegate: TabBarControllerDelegate?

    /// 当前管理的所有子控制器，与 `TabBarItem` 数组一一对应。
    public private(set) var viewControllers: [UIViewController] = []
    /// 当前选中的子控制器。
    public private(set) var selectedViewController: UIViewController?
    /// 底部 TabBar 视图，可直接访问以自定义外观。
    public let tabBar: TabBarView

    /// 当前选中的 tab 索引。
    ///
    /// 设置时会触发子控制器切换动画，但不会通知 delegate。
    public var selectedIndex: Int {
        get {
            tabBar.selectedIndex
        }
        set {
            guard viewControllers.indices.contains(newValue) else {
                return
            }
            selectViewController(at: newValue, animated: true, notifyDelegate: false)
        }
    }

    /// TabBar 的主题样式。
    ///
    /// 设置时会同步更新 TabBar 外观和控制器背景色。
    public var style: TabBarStyle {
        get {
            tabBar.style
        }
        set {
            tabBar.style = newValue
            view.backgroundColor = newValue.backgroundColor
        }
    }

    /// 子控制器视图的容器，铺满整个控制器视图。
    private let contentView = UIView()
    /// TabBar 是否处于隐藏状态。
    private var isTabBarHidden = false
    private weak var insetViewController: UIViewController?
    private var appliedInsets: UIEdgeInsets = .zero

    public init(style: TabBarStyle = .default) {
        tabBar = TabBarView(style: style)
        super.init(nibName: nil, bundle: nil)
        tabBar.delegate = self
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = style.backgroundColor
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(contentView)
        view.addSubview(tabBar)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        #if compiler(>=6.4)
        if #available(iOS 27.1, *) {
            registerForTraitChanges(UITraitCollection.systemTraitsAffectingVerticalBarEdge) { (controller: TabBarController, _: UITraitCollection) in
                controller.view.setNeedsLayout()
            }
        }
        #endif
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTabBarFrame()
        updateSelectedChildInsets()
    }

    override open func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        view.setNeedsLayout()
    }

    // MARK: - 公共方法

    /// 设置子控制器和对应的 TabBar 项。
    ///
    /// - Parameters:
    ///   - viewControllers: 子控制器数组，数量必须与 `items` 一致。
    ///   - items: TabBar 项数组，与 `viewControllers` 一一对应。
    ///   - selectedIndex: 初始选中索引，默认为 0。
    public func setViewControllers(_ viewControllers: [UIViewController], items: [TabBarItem], selectedIndex: Int = 0) {
        precondition(
            viewControllers.count == items.count,
            "TabBarController: viewControllers.count (\(viewControllers.count)) must equal items.count (\(items.count))"
        )

        // 移除旧的子控制器
        for viewController in self.viewControllers where viewController.parent === self {
            viewController.willMove(toParent: nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParent()
        }

        selectedViewController = nil

        self.viewControllers = viewControllers
        tabBar.setItems(items, selectedIndex: selectedIndex)

        guard !viewControllers.isEmpty else {
            return
        }

        let initialIndex = min(max(0, selectedIndex), viewControllers.count - 1)
        selectViewController(at: initialIndex, animated: false, notifyDelegate: false)
    }

    /// 显示或隐藏 TabBar。
    ///
    /// 隐藏时 TabBar 会滑出屏幕底部并淡出，子控制器的 `additionalSafeAreaInsets` 会同步更新。
    public func setTabBarHidden(_ hidden: Bool, animated: Bool) {
        isTabBarHidden = hidden

        let updates = {
            self.tabBar.alpha = hidden ? 0.0 : 1.0
            self.updateTabBarFrame()
            self.view.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseInOut], animations: updates)
        } else {
            updates()
        }

        updateSelectedChildInsets()
    }

    /// 启用或禁用 TabBar 的交互。
    ///
    /// 禁用时 TabBar 会降低透明度（0.7）并忽略触摸事件。
    public func setTabBarEnabled(_ enabled: Bool, animated: Bool) {
        let updates = {
            self.tabBar.isTabBarEnabled = enabled
        }
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: updates)
        } else {
            updates()
        }
    }

    /// 重新加载 TabBar 项（例如更新角标），数量必须与当前 `viewControllers` 一致。
    public func reloadTabBarItems(_ items: [TabBarItem]) {
        precondition(
            items.count == viewControllers.count,
            "TabBarController: items.count (\(items.count)) must equal viewControllers.count (\(viewControllers.count))"
        )
        tabBar.setItems(items, selectedIndex: selectedIndex)
    }

    // MARK: - TabBarViewDelegate

    public func tabBarView(_: TabBarView, shouldSelect _: TabBarItem, at index: Int) -> Bool {
        guard viewControllers.indices.contains(index) else {
            return false
        }
        return delegate?.tabBarController(self, shouldSelect: viewControllers[index], at: index) ?? true
    }

    public func tabBarView(_: TabBarView, didSelect _: TabBarItem, at index: Int) {
        selectViewController(at: index, animated: true, notifyDelegate: true)
    }

    public func tabBarView(_: TabBarView, didReselect _: TabBarItem, at index: Int) {
        guard viewControllers.indices.contains(index) else {
            return
        }
        delegate?.tabBarController(self, didReselect: viewControllers[index], at: index)
    }

    public func tabBarView(_: TabBarView, didDoubleTap _: TabBarItem, at index: Int) {
        guard viewControllers.indices.contains(index) else {
            return
        }
        delegate?.tabBarController(self, didDoubleTap: viewControllers[index], at: index)
    }

    // MARK: - 子控制器切换

    /// 执行子控制器切换。
    ///
    /// 动画效果：
    /// - 旧控制器：layer 级别 scale 缩小（≈0.998），不影响内部 scrollView 的 contentOffset
    /// - 新控制器：从 scale 0.998 放大到 1.0（spring，0.15s，delay 0.1s）+ opacity 0→1（0.1s）
    /// - 旧控制器的 view 在新控制器 opacity 动画完成后移除
    private func selectViewController(at index: Int, animated: Bool, notifyDelegate: Bool) {
        guard viewControllers.indices.contains(index) else {
            return
        }

        let nextViewController = viewControllers[index]
        let previousViewController = selectedViewController
        guard previousViewController !== nextViewController else {
            return
        }

        // transitionScale = (height - 3) / height ≈ 0.998
        // 微小的缩放让切换有轻微的"推远"感，同时避免大幅度变换导致的视觉跳动
        var transitionScale: CGFloat = 0.998
        if let previousView = previousViewController?.view {
            transitionScale = (max(previousView.frame.height, 1.0) - 3.0) / max(previousView.frame.height, 1.0)
        }

        // 1. 旧控制器：layer 级别 scale 动画
        if let previousViewController {
            previousViewController.willMove(toParent: nil)
            if animated {
                previousViewController.view.layer.animate(
                    from: 1.0 as NSNumber, to: transitionScale as NSNumber,
                    keyPath: "transform.scale",
                    timingFunction: kCAMediaTimingFunctionSpring,
                    duration: 0.12,
                    removeOnCompletion: false,
                    additive: false,
                    completion: { completed in
                        if completed {
                            previousViewController.view.layer.removeAllAnimations()
                        }
                    }
                )
            }
            previousViewController.removeFromParent()
            previousViewController.didMove(toParent: nil)
        }

        // 2. 新控制器：添加到容器并播放进入动画
        selectedViewController = nextViewController
        updateSelectedChildInsets()

        nextViewController.willMove(toParent: self)
        addChild(nextViewController)

        nextViewController.view.frame = contentView.bounds
        nextViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if let previousView = previousViewController?.view {
            contentView.insertSubview(nextViewController.view, aboveSubview: previousView)
        } else if nextViewController.view.superview == nil {
            contentView.addSubview(nextViewController.view)
        }
        // 确保 TabBar 始终在最前面
        view.bringSubviewToFront(tabBar)

        if animated {
            // scale: 从 transitionScale 放大到 1.0，spring 曲线，0.15s，延迟 0.1s
            nextViewController.view.layer.animate(
                from: transitionScale as NSNumber, to: 1.0 as NSNumber,
                keyPath: "transform.scale",
                timingFunction: kCAMediaTimingFunctionSpring,
                duration: 0.15, delay: 0.1,
                removeOnCompletion: true, additive: false
            )
            // opacity: 从 0 淡入到 1，0.1s，完成后移除旧 view
            nextViewController.view.layer.allowsGroupOpacity = true
            let previousView = previousViewController?.view
            nextViewController.view.layer.animate(
                from: 0.0 as NSNumber, to: 1.0 as NSNumber,
                keyPath: "opacity",
                timingFunction: CAMediaTimingFunctionName.easeInEaseOut.rawValue,
                duration: 0.1,
                removeOnCompletion: true, additive: false,
                completion: { completed in
                    if completed {
                        nextViewController.view.layer.allowsGroupOpacity = false
                    }
                    previousView?.removeFromSuperview()
                }
            )
        } else {
            previousViewController?.view.removeFromSuperview()
        }

        nextViewController.didMove(toParent: self)

        if notifyDelegate {
            delegate?.tabBarController(self, didSelect: nextViewController, at: index)
        }
    }

    // MARK: - 布局

    /// 更新当前选中子控制器的 `additionalSafeAreaInsets.bottom`。
    ///
    /// 确保子控制器的内容不会被 TabBar 遮挡。
    /// 计算方式：TabBar 总高度 - 系统 safeAreaInsets.bottom（避免重复计算）。
    private func updateSelectedChildInsets() {
        if insetViewController !== selectedViewController {
            if let previous = insetViewController {
                var insets = previous.additionalSafeAreaInsets
                insets.left -= appliedInsets.left
                insets.right -= appliedInsets.right
                insets.bottom -= appliedInsets.bottom
                previous.additionalSafeAreaInsets = insets
            }
            insetViewController = selectedViewController
            appliedInsets = .zero
        }
        guard let selectedViewController else {
            return
        }
        var required = UIEdgeInsets.zero
        if !isTabBarHidden {
            if tabBar.isVertical {
                if tabBar.frame.midX < view.bounds.midX {
                    required.left = max(0, tabBar.frame.maxX + 8 - view.safeAreaInsets.left)
                } else {
                    required.right = max(0, view.bounds.maxX - tabBar.frame.minX + 8 - view.safeAreaInsets.right)
                }
            } else {
                required.bottom = max(0, view.bounds.maxY - tabBar.frame.minY - view.safeAreaInsets.bottom)
            }
        }
        var insets = selectedViewController.additionalSafeAreaInsets
        insets.left += required.left - appliedInsets.left
        insets.right += required.right - appliedInsets.right
        insets.bottom += required.bottom - appliedInsets.bottom
        appliedInsets = required
        if selectedViewController.additionalSafeAreaInsets != insets {
            selectedViewController.additionalSafeAreaInsets = insets
        }
    }

    /// TabBar 占据的总高度（胶囊高度 + 底部间距），用于子控制器 insets 计算。
    ///
    /// 隐藏状态下返回 0。
    public var tabBarTotalHeight: CGFloat {
        isTabBarHidden || tabBar.isVertical ? 0.0 : (tabBar.contentHeight + tabBarBottomInset)
    }

    /// 计算并设置 TabBar 的 frame。
    ///
    /// TabBar 以浮动胶囊形式居中显示在屏幕底部，左右留有 sideInset。
    /// sideInset 根据底部间距动态调整：
    /// - `bottomInset <= 28`（SE / iOS 26 iPhone / iPad mini 等）→ sideInset = 20pt，胶囊适当收窄
    /// - `bottomInset > 28`（iOS 26 以下 Face ID iPhone，34pt）→ sideInset = 12pt，胶囊更宽
    /// 底部空间大时胶囊可以更宽，底部空间小时适当收窄以保持视觉平衡。
    private func updateTabBarFrame() {
        let bounds = view.bounds
        let reservedFrames: [CGRect]
        #if compiler(>=6.4)
        if #available(iOS 27.1, *) {
            reservedFrames = (view.reservedRegions(kind: .occlusion) + view.reservedRegions(kind: .division))
                .filter(\.isActive).map(\.frame)
        } else {
            reservedFrames = []
        }
        #else
        reservedFrames = []
        #endif
        if tabBar.isVertical {
            var isLeft = false
            #if compiler(>=6.4)
            if #available(iOS 27.1, *) {
                let leadingIsLeft = view.effectiveUserInterfaceLayoutDirection != .rightToLeft
                isLeft = traitCollection.verticalBarEdge == .leading ? leadingIsLeft : !leadingIsLeft
            }
            #endif
            let safeFrame = view.safeAreaLayoutGuide.layoutFrame.insetBy(dx: 8, dy: 8)
            let available = Self.availableBarRegion(in: safeFrame, avoiding: reservedFrames, vertical: true, isLeft: isLeft)
            let width = min(64, max(0, available.width))
            let height = min(CGFloat(tabBar.items.count) * 56 + 8, max(0, available.height))
            let x = isLeft ? available.minX : available.maxX - width
            tabBar.frame = CGRect(x: isTabBarHidden ? (isLeft ? -width : bounds.maxX) : x,
                                  y: available.maxY - height, width: width, height: height)
            return
        }
        let bottomInset = tabBarBottomInset
        let sideInset: CGFloat = bottomInset <= 28.0 ? 20.0 : 12.0
        let tabBarHeight = tabBar.contentHeight
        let tabBarWidth = max(0, bounds.width - view.safeAreaInsets.left - view.safeAreaInsets.right - sideInset * 2.0)
        let tabBarY: CGFloat

        if isTabBarHidden {
            // 隐藏时推到屏幕底部以下
            tabBarY = bounds.height
        } else {
            tabBarY = bounds.height - tabBarHeight - bottomInset
        }

        let proposed = CGRect(
            x: view.safeAreaInsets.left + sideInset,
            y: tabBarY,
            width: tabBarWidth,
            height: tabBarHeight
        )
        tabBar.frame = Self.availableBarRegion(in: proposed, avoiding: reservedFrames, vertical: false, isLeft: false)
    }

    /// 按系统保留区域切分候选矩形，选择能容纳控件且最接近系统栏位置的区域。
    static func availableBarRegion(in frame: CGRect, avoiding regions: [CGRect], vertical: Bool, isLeft: Bool) -> CGRect {
        var candidates = [frame]
        for region in regions {
            candidates = candidates.flatMap { candidate -> [CGRect] in
                let overlap = candidate.intersection(region)
                guard !overlap.isNull, !overlap.isEmpty else { return [candidate] }
                return [
                    CGRect(x: candidate.minX, y: candidate.minY, width: overlap.minX - candidate.minX, height: candidate.height),
                    CGRect(x: overlap.maxX, y: candidate.minY, width: candidate.maxX - overlap.maxX, height: candidate.height),
                    CGRect(x: candidate.minX, y: candidate.minY, width: candidate.width, height: overlap.minY - candidate.minY),
                    CGRect(x: candidate.minX, y: overlap.maxY, width: candidate.width, height: candidate.maxY - overlap.maxY),
                ].filter { $0.width >= 44 && $0.height >= 44 }
            }
        }
        return candidates.max { lhs, rhs in
            if vertical {
                let leftDistance = isLeft ? lhs.minX - frame.minX : frame.maxX - lhs.maxX
                let rightDistance = isLeft ? rhs.minX - frame.minX : frame.maxX - rhs.maxX
                if leftDistance != rightDistance { return leftDistance > rightDistance }
                return lhs.height < rhs.height
            }
            if lhs.maxY != rhs.maxY { return lhs.maxY < rhs.maxY }
            return lhs.width < rhs.width
        } ?? CGRect(origin: frame.origin, size: .zero)
    }

    /// TabBar 底部间距。
    ///
    /// 通过 `DeviceMetrics.onScreenNavigationHeight` 做设备特定映射：
    /// - iOS 26+ iPhone 全系列硬编码 20pt（系统 home indicator 高度变化）
    /// - iOS 26 以下按设备型号返回实际 safeAreaInsets.bottom（如 34pt / 21pt）
    /// - 无 home indicator 的设备（SE、旧 iPad）返回 0
    ///
    /// 简化实现：直接读 `safeAreaInsets.bottom`，iOS 26+ 取 `min(safeArea, 20)` 对齐原版行为。
    /// 最终结果至少为 8pt，保证无 home indicator 设备也有最小底部间距。
    private var tabBarBottomInset: CGFloat {
        let bottomSafeArea = view.safeAreaInsets.bottom
        let navigationHeight: CGFloat
        if #available(iOS 26.0, *) {
            navigationHeight = bottomSafeArea.isLessThanOrEqualTo(0.0) ? 0.0 : min(bottomSafeArea, 20.0)
        } else {
            navigationHeight = bottomSafeArea.isLessThanOrEqualTo(0.0) ? 0.0 : bottomSafeArea
        }
        return max(navigationHeight, 8.0)
    }
}
