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
        tabBar.onExpandedChange = { [weak self] in
            // 与 TabBarView 内部展开动画使用同一 spring，避免外框尺寸突变。
            self?.updateTabBarFrame(transition: .spring(duration: 0.4))
        }
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

    override open func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        #if compiler(>=6.4)
        if #available(iOS 27.1, *), let window = view.window {
            // 提前创建两侧 guide，保证姿态切换后的首次布局即可拿到已求解的系统轨道。
            for edge in [NSDirectionalRectEdge.leading, .trailing] {
                _ = Self.verticalBarGuide(in: window, on: edge)
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

    /// 更新当前选中子控制器的 `additionalSafeAreaInsets`，确保内容不被 TabBar 遮挡。
    ///
    /// - 横向：bottom = TabBar 顶部到屏幕底部的距离 - 系统 safeAreaInsets.bottom（避免重复计算）。
    /// - 纵向：在 TabBar 所在侧补足超出系统 safe area 的部分；系统纵向栏 safe area 通常已覆盖轨道，此时为 0。
    /// 只增减自身追加的部分，保留调用方设置的 insets。
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
                // 按轨道宽度计算（展开时以轨道为中心），长按展开覆盖在内容之上，不改变 insets。
                let railHalfWidth = TabBarView.verticalBarExtent * 0.5
                if tabBar.frame.midX < view.bounds.midX {
                    required.left = max(0, tabBar.frame.midX + railHalfWidth + 8 - view.safeAreaInsets.left)
                } else {
                    required.right = max(0, view.bounds.maxX - (tabBar.frame.midX - railHalfWidth) + 8 - view.safeAreaInsets.right)
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
    /// iPhone Duo 纵向栏姿态（闭合外屏、展开内屏横握）：贴系统纵向栏轨道底部，宽度与轨道一致；
    /// 隐藏时沿所在侧水平滑出屏幕。
    ///
    /// 其余情况 TabBar 以浮动胶囊形式居中显示在屏幕底部，左右留有 sideInset，并避开保留区域。
    /// sideInset 根据底部间距动态调整：
    /// - `bottomInset <= 28`（SE / iOS 26 iPhone / iPad mini 等）→ sideInset = 20pt，胶囊适当收窄
    /// - `bottomInset > 28`（iOS 26 以下 Face ID iPhone，34pt）→ sideInset = 12pt，胶囊更宽
    /// 底部空间大时胶囊可以更宽，底部空间小时适当收窄以保持视觉平衡。
    private func updateTabBarFrame(transition: ViewTransition = .immediate) {
        let bounds = view.bounds
        if let rail = verticalBarRail {
            // 系统纵向栏自上而下为灵动岛、状态栏、Toolbar、TabBar（HIG），TabBar 贴轨道底部；
            // 轨道放不下全部 item 时由 TabBarView 内部纵向滚动。
            // 长按展开时以轨道中线为中心加宽、贴轨道底部向上长高，不超出 view。
            tabBar.isVertical = true
            let height = min(tabBar.verticalContentHeight, tabBar.isExpanded ? rail.maxY - bounds.minY : rail.height)
            let isLeft = rail.midX < bounds.midX
            let width = tabBar.isExpanded ? min(tabBar.expandedVerticalWidth, bounds.width) : rail.width
            let x = min(max(rail.midX - width * 0.5, bounds.minX), bounds.maxX - width)
            transition.setFrame(view: tabBar, frame: CGRect(
                x: isTabBarHidden ? (isLeft ? bounds.minX - width : bounds.maxX) : x,
                y: rail.maxY - height,
                width: width,
                height: height
            ))
            return
        }
        tabBar.isVertical = false
        let reservedFrames: [CGRect]
        #if compiler(>=6.4)
        if #available(iOS 27.1, *) {
            reservedFrames = (view.reservedRegions(kind: .occlusion).filter(\.isActive).map(\.frame)
                + view.reservedRegions(kind: .division).filter(\.isActive).map(\.frame))
        } else {
            reservedFrames = []
        }
        #else
        reservedFrames = []
        #endif
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
        tabBar.frame = Self.availableBarRegion(in: proposed, avoiding: reservedFrames)
    }

    /// 系统为纵向栏提供的控制轨道（`view` 坐标系）；不处于纵向栏姿态（如展开内屏竖握）时返回 nil。
    ///
    /// `verticalBarEdge` 只表示系统偏好的边，需同时拿到非空 layout guide 才使用纵向布局。
    /// 轨道已由系统避开摄像头、状态栏和折叠区域，并与状态栏处于同一列。
    ///
    /// guide 取自 window 而非 `view`：外层 `UINavigationController` 会在纵向栏一侧给子控制器追加
    /// safe area（如分屏左侧时 leading 84pt），`view` 上的 bar guide 会叠在这块 safe area 之后，偏离系统纵向栏所在列。
    private var verticalBarRail: CGRect? {
        #if compiler(>=6.4)
        if #available(iOS 27.1, *), traitCollection.verticalBarEdge != .unspecified, let window = view.window {
            let edge: NSDirectionalRectEdge = traitCollection.verticalBarEdge == .leading ? .leading : .trailing
            let windowRail = Self.verticalBarGuide(in: window, on: edge).layoutFrame
            guard !windowRail.isEmpty else { return nil }
            let rail = view.convert(windowRail, from: window)
            // ponytail: 只处理控制器横向铺满 window 的场景；嵌在分栏等局部容器里时轨道可能落在 view 外，退回横向布局。
            return rail.minX >= view.bounds.minX && rail.maxX <= view.bounds.maxX ? rail : nil
        }
        #endif
        return nil
    }

    #if compiler(>=6.4)
    /// 指定边的纵向栏 layout guide，宽度与系统纵向栏一致。
    ///
    /// guide 在首次访问时创建，创建当次 `layoutFrame` 为空，需提前访问一次。
    @available(iOS 27.1, *)
    private static func verticalBarGuide(in window: UIWindow, on edge: NSDirectionalRectEdge) -> UILayoutGuide {
        window.layoutGuide(for: .bar(onEdge: edge, extent: TabBarView.verticalBarExtent))
    }
    #endif

    /// 按系统保留区域（摄像头遮挡、折叠分割）切分横向候选矩形，选择最靠下、最宽的区域。
    static func availableBarRegion(in frame: CGRect, avoiding regions: [CGRect]) -> CGRect {
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
