//
//  TabBarView.swift
//  TabBar
//
//  Created by Sun on 2026/4/20.
//

import UIKit

// MARK: - TabBarViewDelegate

/// TabBar 视图的代理协议。
///
/// 提供 tab 选中、重选、双击、长按等交互事件的回调。
/// `TabBarController` 实现此协议来驱动子控制器切换。
public protocol TabBarViewDelegate: AnyObject {
    /// 询问是否允许选中指定 tab。
    func tabBarView(_ tabBarView: TabBarView, shouldSelect item: TabBarItem, at index: Int) -> Bool
    /// 选中了一个新的 tab。
    func tabBarView(_ tabBarView: TabBarView, didSelect item: TabBarItem, at index: Int)
    /// 重选了当前已选中的 tab。
    func tabBarView(_ tabBarView: TabBarView, didReselect item: TabBarItem, at index: Int)
    /// 双击了某个 tab。
    func tabBarView(_ tabBarView: TabBarView, didDoubleTap item: TabBarItem, at index: Int)
    /// 长按了某个 tab。iPhone Duo 纵向布局下长按用于展开显示标题，不回调此方法。
    func tabBarView(_ tabBarView: TabBarView, didLongPress item: TabBarItem, at index: Int)
}

public extension TabBarViewDelegate {
    func tabBarView(_: TabBarView, shouldSelect _: TabBarItem, at _: Int) -> Bool {
        true
    }

    func tabBarView(_: TabBarView, didSelect _: TabBarItem, at _: Int) {}
    func tabBarView(_: TabBarView, didReselect _: TabBarItem, at _: Int) {}
    func tabBarView(_: TabBarView, didDoubleTap _: TabBarItem, at _: Int) {}
    func tabBarView(_: TabBarView, didLongPress _: TabBarItem, at _: Int) {}
}

// MARK: - TabBarView

/// 浮动胶囊式 TabBar 视图。
///
/// 负责 TabBar 的渲染和交互，内部通过 `TabBarContentView` 管理具体的布局和动画。
/// 通常由 `TabBarController` 持有和管理，也可以独立使用。
public final class TabBarView: UIView {
    /// 单个 tab 项的高度。
    static let itemHeight: CGFloat = 56.0
    /// 胶囊内边距。
    static let innerInset: CGFloat = 4.0
    /// iPhone Duo 纵向控制轨道宽度，与系统纵向栏按钮（48pt，Device Hub 实测）一致。
    static let verticalBarExtent: CGFloat = 48.0
    /// 纵向布局单个 tab 项的高度，与轨道宽度一致，使选中指示接近正方形。
    static let verticalItemHeight: CGFloat = verticalBarExtent

    /// 是否按 iPhone Duo 纵向控制轨道布局。
    ///
    /// 由 `TabBarController` 根据系统纵向栏 layout guide 统一设置，避免 trait 与实际 frame 不一致。
    var isVertical = false {
        didSet {
            guard oldValue != isVertical else { return }
            isExpanded = false
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// 纵向布局时是否位于屏幕右侧，决定展开方向与标题位置。由 `TabBarController` 设置。
    var isOnRightEdge = false

    /// 纵向布局长按展开中：向屏幕内侧放大并显示标题，松手后收起。
    private(set) var isExpanded = false

    /// 展开状态变化时调用，由 `TabBarController` 重新计算 frame。
    var onExpandedChange: (() -> Void)?

    /// 纵向布局时完整展示所有 item 所需的高度。
    var verticalContentHeight: CGFloat {
        CGFloat(items.count) * Self.verticalItemHeight + Self.innerInset * 2.0
    }

    /// 纵向展开后的宽度：轨道宽度 + 最长标题 + 两侧留白。
    var expandedVerticalWidth: CGFloat {
        let titleWidth = items.map { TabBarItemContentView.measureSideTitleWidth($0.title) }.max() ?? 0.0
        return Self.verticalBarExtent + titleWidth + 16.0
    }

    /// 代理，接收交互事件。
    public weak var delegate: TabBarViewDelegate?

    /// 当前的 TabBar 项数组。设置后会触发重新布局。
    public var items: [TabBarItem] = [] {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// 当前选中的 tab 索引。
    ///
    /// 设置时会自动 clamp 到有效范围，并在值变化时标记需要动画更新。
    public var selectedIndex: Int = 0 {
        didSet {
            let upperBound = max(0, items.count - 1)
            let clampedIndex = min(max(0, selectedIndex), upperBound)
            if clampedIndex != selectedIndex {
                selectedIndex = clampedIndex
                return
            }
            if oldValue != selectedIndex {
                needsAnimatedSelectionUpdate = true
                setNeedsLayout()
            }
        }
    }

    /// 主题样式。设置后会触发重新布局以更新颜色。
    public var style: TabBarStyle = .default {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// 是否启用交互。禁用时降低透明度并忽略触摸。
    public var isTabBarEnabled: Bool = true {
        didSet {
            isUserInteractionEnabled = isTabBarEnabled
            alpha = isTabBarEnabled ? 1.0 : 0.7
        }
    }

    /// 内容高度（胶囊高度）。
    ///
    /// 优先使用实际测量值，未测量时返回估算值（itemHeight + innerInset * 2）。
    public var contentHeight: CGFloat {
        if tabBarContentSize.height > 0.0 {
            return tabBarContentSize.height
        }
        return estimatedContentHeight
    }

    override public var intrinsicContentSize: CGSize {
        isVertical
            ? CGSize(width: Self.verticalBarExtent, height: verticalContentHeight)
            : CGSize(width: UIView.noIntrinsicMetric, height: contentHeight)
    }

    /// 核心内容视图，负责所有 tab 项的布局、渲染和手势处理。
    private let tabBarContentView = TabBarContentView()
    private let scrollView = UIScrollView()
    /// 上一次 `TabBarContentView.update()` 返回的实际尺寸。
    private var tabBarContentSize: CGSize = .zero
    /// 是否需要在下次 layout 时使用动画更新选中状态。
    private var needsAnimatedSelectionUpdate = false

    public init(style: TabBarStyle = .default) {
        self.style = style
        super.init(frame: .zero)
        backgroundColor = .clear

        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.clipsToBounds = false
        addSubview(scrollView)
        scrollView.addSubview(tabBarContentView)
        tabBarContentView.deferSelection(to: scrollView.panGestureRecognizer)
        // TabBarContentView 在手势交互时会主动请求更新（如拖拽切换 tab）
        tabBarContentView.onNeedsUpdate = { [weak self] transition in
            self?.performUpdate(transition: transition)
        }
        tabBarContentView.onExpandedChange = { [weak self] expanded in
            self?.setExpanded(expanded)
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 公共方法

    /// 设置 TabBar 项和初始选中索引。
    public func setItems(_ items: [TabBarItem], selectedIndex: Int = 0) {
        self.items = items
        self.selectedIndex = selectedIndex
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    /// 设置选中索引，可控制是否使用动画。
    public func setSelectedIndex(_ index: Int, animated: Bool) {
        needsAnimatedSelectionUpdate = animated
        selectedIndex = index
    }

    private func setExpanded(_ expanded: Bool) {
        guard isVertical || !expanded, isExpanded != expanded else { return }
        isExpanded = expanded
        needsAnimatedSelectionUpdate = true
        setNeedsLayout()
        onExpandedChange?()
        layoutIfNeeded()
    }

    // MARK: - 布局

    override public func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0.0 else { return }

        let transition: ViewTransition = needsAnimatedSelectionUpdate ? .spring(duration: 0.4) : .immediate
        performUpdate(transition: transition)
        needsAnimatedSelectionUpdate = false
    }

    override public func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    /// 执行完整的内容更新：构建 items → 调用 TabBarContentView.update() → 更新 frame。
    ///
    /// `outerInsets` 传入 TabBarView 在父视图中的 x 偏移，
    /// 用于 LiquidLensView 的 restingBackgroundView 溢出计算，
    /// 防止 spring 回弹时露出底层背景。
    private func performUpdate(transition: ViewTransition) {
        guard bounds.width > 0.0 else { return }

        // 将 TabBarItem 数据模型转换为 TabBarContentView 的内部 Item（附带交互闭包）
        let contentItems: [TabBarContentView.Item] = items.enumerated().map { index, item in
            TabBarContentView.Item(
                tabBarItem: item,
                action: { [weak self] _ in
                    self?.handleSelection(at: index)
                },
                doubleTapAction: { [weak self] in
                    guard let self, self.items.indices.contains(index) else { return }
                    self.delegate?.tabBarView(self, didDoubleTap: self.items[index], at: index)
                },
                contextAction: { [weak self] _, _ in
                    guard let self, self.items.indices.contains(index) else { return }
                    self.delegate?.tabBarView(self, didLongPress: self.items[index], at: index)
                }
            )
        }

        let params = TabBarContentView.Params(
            theme: style,
            selectedIndex: items.indices.contains(selectedIndex) ? selectedIndex : nil,
            outerInsets: isVertical
                ? UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
                : UIEdgeInsets(top: 0.0, left: frame.origin.x, bottom: 0.0, right: frame.origin.x),
            isVertical: isVertical,
            isExpanded: isExpanded,
            isOnRightEdge: isOnRightEdge
        )

        tabBarContentSize = tabBarContentView.update(
            items: contentItems,
            params: params,
            availableSize: CGSize(width: bounds.width, height: 100.0),
            transition: transition
        )

        if tabBarContentSize.height > 0.0 {
            invalidateIntrinsicContentSize()
        }

        scrollView.frame = bounds
        scrollView.isScrollEnabled = isVertical && !isExpanded && tabBarContentSize.height > bounds.height
        scrollView.clipsToBounds = isVertical && tabBarContentSize.height > bounds.height
        scrollView.contentSize = tabBarContentSize
        if !scrollView.isScrollEnabled, !isExpanded {
            scrollView.contentOffset = .zero
        }
        tabBarContentView.frame = CGRect(
            x: floor((bounds.width - tabBarContentSize.width) * 0.5),
            y: isVertical ? 0 : max(0.0, bounds.height - tabBarContentSize.height),
            width: tabBarContentSize.width,
            height: tabBarContentSize.height
        )
    }

    // MARK: - 交互处理

    /// 处理 tab 选中逻辑：shouldSelect 检查 → 重选 / 新选分发。
    private func handleSelection(at index: Int) {
        guard items.indices.contains(index) else { return }

        let item = items[index]
        let shouldSelect = delegate?.tabBarView(self, shouldSelect: item, at: index) ?? true
        guard shouldSelect else { return }

        if selectedIndex == index {
            delegate?.tabBarView(self, didReselect: item, at: index)
            return
        }

        selectedIndex = index
        delegate?.tabBarView(self, didSelect: item, at: index)
    }

    /// 估算内容高度，在首次 update 之前使用。
    private var estimatedContentHeight: CGFloat {
        Self.itemHeight + Self.innerInset * 2.0
    }
}
