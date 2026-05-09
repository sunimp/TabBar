//
//  TabBarContentView.swift
//  TabBar
//
//  Created by Sun on 2026/4/21.
//

import UIKit

// MARK: - TabBarContentView

/// TabBar 的核心内容视图，负责所有 tab 项的布局、渲染和手势处理。
///
/// 视图层级结构：
/// ```
/// TabBarContentView
/// └── GlassBackgroundContainerView（毛玻璃背景容器）
///     └── containerView
///         └── LiquidLensView（液态透镜选中指示器）
///             ├── contentView → 各 TabBarItemContentView（未选中态）
///             └── selectedContentView → 各 TabBarItemContentView（选中态）
/// ```
///
/// 每个 tab 同时维护两个 `TabBarItemContentView` 实例（未选中态 + 选中态），
/// 配合 LiquidLens 的 punchout 机制实现：lens 区域内显示选中态，区域外显示未选中态。
final class TabBarContentView: UIView, UIGestureRecognizerDelegate {
    /// 内部 item 数据，包含 TabBarItem 数据模型和交互闭包。
    struct Item {
        let tabBarItem: TabBarItem
        /// 选中回调，参数表示是否为长按触发。
        let action: (Bool) -> Void
        /// 双击回调。为 nil 时不启用双击检测。
        let doubleTapAction: (() -> Void)?
        /// 长按上下文菜单回调。
        let contextAction: ((UILongPressGestureRecognizer, ContextExtractedContentContainingView) -> Void)?

        /// 用于视图复用的稳定标识符，取自 `TabBarItem.id`。
        var id: AnyHashable {
            AnyHashable(tabBarItem.id)
        }
    }

    /// 更新参数，包含主题、选中索引和外部 insets。
    struct Params: Equatable {
        /// 当前主题样式。
        var theme: TabBarStyle
        /// 当前选中的 tab 索引，nil 表示无选中。
        var selectedIndex: Int?
        /// TabBarView 在父视图中的外部 insets，用于 LiquidLens 的溢出计算。
        var outerInsets: UIEdgeInsets
    }

    /// 毛玻璃背景容器（iOS 26+ 使用 UIGlassContainerEffect，低版本使用普通 UIView）。
    private let backgroundContainer: GlassBackgroundContainerView
    /// 液态透镜选中指示器，管理选中态的视觉效果。
    private let liquidLensView: LiquidLensView
    /// 手势和内容的容器视图。
    private let containerView: UIView

    /// 未选中态的 item 视图字典，key 为 item.id。
    private var itemContentViews: [AnyHashable: TabBarItemContentView] = [:]
    /// 选中态的 item 视图字典，key 为 item.id。
    /// 与 `itemContentViews` 一一对应，通过 LiquidLens 的 mask 机制切换显示。
    private var selectedItemContentViews: [AnyHashable: TabBarItemContentView] = [:]

    /// 自定义 tab 选择手势识别器，支持按下 → 拖拽 → 松手切换。
    private var tabSelectionRecognizer: TabSelectionRecognizer?

    /// 当前的 item 数据数组。
    private(set) var items: [Item] = []
    /// 上一次更新的参数，用于检测变化。
    private var params: Params?

    /// 当手势交互需要触发视图更新时调用（如拖拽切换 tab 时实时更新 lens 位置）。
    var onNeedsUpdate: ((ViewTransition) -> Void)?

    /// 拖拽手势状态：起始 X、当前 X、item 宽度、当前悬停的 item id。
    private var selectionGestureState: (startX: CGFloat, currentX: CGFloat, itemWidth: CGFloat, itemId: AnyHashable)?
    /// 双击等待期间临时覆盖的选中 item id，用于在 timer 窗口内保持 lens 位置。
    private var overrideSelectedItemId: AnyHashable?
    /// 双击检测的 pending 状态：item id、之前选中的 id、等待 timer。
    private var pendingDoubleTapItem: (id: AnyHashable, previouslySelectedId: AnyHashable?, timer: Foundation.Timer)?

    override init(frame: CGRect) {
        backgroundContainer = GlassBackgroundContainerView()
        liquidLensView = LiquidLensView(kind: .externalContainer)
        containerView = UIView()

        super.init(frame: frame)

        // 强制 compact size class，确保 TabBar 在所有设备上使用紧凑布局
        if #available(iOS 17.0, *) {
            traitOverrides.verticalSizeClass = .compact
            traitOverrides.horizontalSizeClass = .compact
        }

        addSubview(backgroundContainer)
        backgroundContainer.contentView.addSubview(containerView)
        containerView.addSubview(liquidLensView)

        // 自定义手势：支持按下立即响应 + 拖拽切换 tab
        let tabRecognizer = TabSelectionRecognizer(target: self, action: #selector(onTabSelectionGesture(_:)))
        tabSelectionRecognizer = tabRecognizer
        containerView.addGestureRecognizer(tabRecognizer)

        // 长按手势：触发上下文菜单
        let contextGesture = UILongPressGestureRecognizer(target: self, action: #selector(onContextGesture(_:)))
        contextGesture.minimumPressDuration = 0.3
        containerView.addGestureRecognizer(contextGesture)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        pendingDoubleTapItem?.timer.invalidate()
    }

    /// 允许 TabSelectionRecognizer 和 UILongPressGestureRecognizer 同时识别。
    func gestureRecognizer(_: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        true
    }

    // MARK: - 更新入口

    /// 执行完整的内容更新。
    ///
    /// 流程：清理 pending 状态 → 计算宽度 → 布局 items → 更新容器 → 更新 lens → 更新背景。
    ///
    /// - Parameters:
    ///   - items: tab 项数据数组。
    ///   - params: 更新参数（主题、选中索引、外部 insets）。
    ///   - availableSize: 可用尺寸（宽度上限 500pt）。
    ///   - transition: 动画配置。
    /// - Returns: 实际内容尺寸。
    func update(items: [Item], params: Params, availableSize: CGSize, transition: ViewTransition) -> CGSize {
        let availableSize = CGSize(width: min(500.0, availableSize.width), height: availableSize.height)

        // items 变更时清理双击等待状态和手势状态
        cleanupPendingStateIfNeeded(newItems: items)

        let previousParams = self.params
        self.items = items
        self.params = params

        overrideUserInterfaceStyle = params.theme.isDark ? .dark : .light

        let innerInset: CGFloat = 4.0
        let itemHeight: CGFloat = 56.0

        // 1. 计算每个 item 的宽度
        let (itemWidths, totalItemsWidth) = calculateItemWidths(
            items: items,
            availableItemsWidth: availableSize.width - innerInset * 2.0
        )

        let contentWidth = innerInset * 2.0 + totalItemsWidth
        let tabsSize = CGSize(width: min(availableSize.width, contentWidth), height: itemHeight + innerInset * 2.0)

        // 2. 布局所有 item 视图
        let selectionFrame = layoutItemViews(
            items: items,
            itemWidths: itemWidths,
            tabsSize: tabsSize,
            innerInset: innerInset,
            itemHeight: itemHeight,
            previousParams: previousParams,
            params: params,
            transition: transition
        )

        // 3. 布局容器
        let tabsFrame = CGRect(origin: .zero, size: tabsSize)
        transition.setFrame(view: containerView, frame: tabsFrame)
        transition.setFrame(view: liquidLensView, frame: tabsFrame)

        // 4. 更新 Liquid Lens 选中指示器
        let lensSelection = calculateLensSelection(
            selectionFrame: selectionFrame,
            tabsSize: tabsSize,
            innerInset: innerInset
        )
        liquidLensView.update(
            size: tabsSize,
            selectionOrigin: CGPoint(x: lensSelection.x, y: 0.0),
            selectionSize: CGSize(width: lensSelection.width, height: tabsSize.height),
            inset: innerInset,
            outerInsets: params.outerInsets,
            isDark: params.theme.isDark,
            isLifted: selectionGestureState != nil,
            isCollapsed: false,
            transition: transition
        )

        // 5. 更新毛玻璃背景
        transition.setFrame(view: backgroundContainer, frame: tabsFrame)
        backgroundContainer.update(size: tabsSize, isDark: params.theme.isDark, transition: transition)

        return tabsSize
    }

    // MARK: - 布局计算

    /// items 变更时清理双击等待状态和手势状态，防止 timer 回调访问已不存在的 item。
    private func cleanupPendingStateIfNeeded(newItems: [Item]) {
        let newIds = Set(newItems.map(\.id))
        let oldIds = Set(items.map(\.id))
        guard newIds != oldIds else { return }

        if let pending = pendingDoubleTapItem {
            pending.timer.invalidate()
            pendingDoubleTapItem = nil
        }
        overrideSelectedItemId = nil
        selectionGestureState = nil
    }

    /// 根据 items 和可用宽度，计算每个 item 的最终宽度。
    ///
    /// 策略：如果所有 item 的自然宽度都不超过等分宽度，则使用等分；否则按自然宽度比例分配。
    private func calculateItemWidths(
        items: [Item],
        availableItemsWidth: CGFloat
    ) -> (widths: [CGFloat], totalWidth: CGFloat) {
        // 测量每个 item 的无约束自然宽度
        var unboundWidths: [CGFloat] = []
        var unboundSum: CGFloat = 0.0
        for item in items {
            let w = TabBarItemContentView.measureWidth(item: item.tabBarItem)
            unboundWidths.append(w)
            unboundSum += w
        }

        // 等分宽度
        let equalWidth = floorToScreenPixels(availableItemsWidth / CGFloat(max(1, items.count)))
        if unboundWidths.allSatisfy({ $0 <= equalWidth }) {
            // 所有 item 都能放进等分宽度，使用等分
            let widths = Array(repeating: equalWidth, count: items.count)
            return (widths, equalWidth * CGFloat(items.count))
        } else {
            // 有 item 超出等分宽度，按自然宽度比例分配
            let norm = availableItemsWidth / unboundSum
            var widths: [CGFloat] = []
            var total: CGFloat = 0.0
            for w in unboundWidths {
                let iw = floorToScreenPixels(w * norm)
                widths.append(iw)
                total += iw
            }
            return (widths, total)
        }
    }

    /// 布局所有 item 视图（未选中态 + 选中态），返回选中 item 的 frame。
    ///
    /// 同时处理视图复用（新建/复用）、选中状态判断、动画播放和过期视图清理。
    private func layoutItemViews(
        items: [Item],
        itemWidths: [CGFloat],
        tabsSize: CGSize,
        innerInset: CGFloat,
        itemHeight: CGFloat,
        previousParams: Params?,
        params: Params,
        transition: ViewTransition
    ) -> CGRect? {
        var validIds: [AnyHashable] = []
        var selectionFrame: CGRect?
        var nextItemX: CGFloat = innerInset

        for (index, item) in items.enumerated() {
            validIds.append(item.id)
            let itemSize = CGSize(width: itemWidths[index], height: itemHeight)

            // 复用或创建未选中态视图
            let isNew: Bool
            let itemView: TabBarItemContentView
            if let existing = itemContentViews[item.id] {
                itemView = existing
                isNew = false
            } else {
                itemView = TabBarItemContentView()
                itemView.isUserInteractionEnabled = false
                itemContentViews[item.id] = itemView
                liquidLensView.contentView.addSubview(itemView)
                isNew = true
            }

            // 复用或创建选中态视图
            let selectedView: TabBarItemContentView
            if let existing = selectedItemContentViews[item.id] {
                selectedView = existing
            } else {
                selectedView = TabBarItemContentView()
                selectedView.isUserInteractionEnabled = false
                selectedItemContentViews[item.id] = selectedView
                liquidLensView.selectedContentView.addSubview(selectedView)
            }

            // 判断选中状态：双击等待期间使用 overrideSelectedItemId
            let isItemSelected: Bool
            if let override = overrideSelectedItemId {
                isItemSelected = override == item.id
            } else {
                isItemSelected = params.selectedIndex == index
            }

            // 新建的视图不使用动画
            let itemTransition: ViewTransition = isNew ? .immediate : transition

            // 更新两套视图的内容
            itemView.update(item: item.tabBarItem, theme: params.theme, isSelected: false, availableSize: itemSize, transition: itemTransition)
            selectedView.update(item: item.tabBarItem, theme: params.theme, isSelected: true, availableSize: itemSize, transition: itemTransition)

            // 计算 frame
            let itemFrame = CGRect(origin: CGPoint(x: nextItemX, y: floor((tabsSize.height - itemSize.height) * 0.5)), size: itemSize)
            nextItemX += itemSize.width
            if isItemSelected { selectionFrame = itemFrame }

            // 设置 frame 和 scale
            itemTransition.setFrame(view: itemView, frame: itemFrame)
            itemTransition.setPosition(view: selectedView, position: CGPoint(x: itemFrame.midX, y: itemFrame.midY))
            itemTransition.setBounds(view: selectedView, bounds: CGRect(origin: .zero, size: itemFrame.size))
            // 拖拽状态下选中态视图放大 1.15 倍
            itemTransition.setScale(view: selectedView, scale: selectionGestureState != nil ? 1.15 : 1.0)

            // 新选中时播放 Lottie 动画
            if let prev = previousParams, prev.selectedIndex != index, isItemSelected {
                itemView.playSelectionAnimation()
                selectedView.playSelectionAnimation()
            }
        }

        // 移除不再存在的 item 视图
        for id in itemContentViews.keys where !validIds.contains(id) {
            itemContentViews.removeValue(forKey: id)?.removeFromSuperview()
            selectedItemContentViews.removeValue(forKey: id)?.removeFromSuperview()
        }

        return selectionFrame
    }

    /// 计算 Liquid Lens 选中区域的位置和尺寸。
    ///
    /// 优先使用拖拽手势状态（实时跟随手指），其次使用选中 item 的 frame，最后兜底默认值。
    private func calculateLensSelection(
        selectionFrame: CGRect?,
        tabsSize: CGSize,
        innerInset: CGFloat
    ) -> (x: CGFloat, width: CGFloat) {
        var result: (x: CGFloat, width: CGFloat)
        if let gesture = selectionGestureState {
            // 拖拽状态：lens 跟随手指
            result = (gesture.currentX, gesture.itemWidth + innerInset * 2.0)
        } else if let sf = selectionFrame {
            // 正常状态：lens 对齐选中 item
            result = (sf.minX - innerInset, sf.width + innerInset * 2.0)
        } else {
            // 兜底：无选中时的默认位置
            result = (0.0, 56.0)
        }
        // clamp 到有效范围
        result.x = max(0.0, min(result.x, tabsSize.width - result.width))
        return result
    }

    // MARK: - 手势处理

    /// 长按手势处理：触发上下文菜单。
    @objc private func onContextGesture(_ recognizer: UILongPressGestureRecognizer) {
        guard case .began = recognizer.state else { return }
        let point = recognizer.location(in: containerView)
        guard let itemId = itemId(at: point) else { return }
        guard let item = items.first(where: { $0.id == itemId }), item.contextAction != nil else { return }

        // 取消正在进行的 tab 选择手势
        tabSelectionRecognizer?.state = .cancelled
        selectionGestureState = nil

        guard let itemView = itemContentViews[itemId] else { return }
        item.contextAction?(recognizer, itemView.contextContainerView)
    }

    /// Tab 选择手势处理：支持按下 → 拖拽 → 松手切换，以及双击检测。
    ///
    /// 双击检测机制：
    /// 1. 第一次点击后启动 0.18s 的 timer
    /// 2. timer 窗口内再次点击同一 tab → 触发 doubleTapAction
    /// 3. timer 超时 → 清除 overrideSelectedItemId，恢复正常选中状态
    @objc private func onTabSelectionGesture(_ recognizer: TabSelectionRecognizer) {
        guard !items.isEmpty else { return }
        switch recognizer.state {
        case .began:
            if let itemId = itemId(at: recognizer.location(in: self)), let itemView = itemContentViews[itemId] {
                // 如果正在等待双击但点击了不同的 tab，取消双击等待
                if let pending = pendingDoubleTapItem, pending.id != itemId {
                    pendingDoubleTapItem = nil
                    pending.timer.invalidate()
                }
                let startX = itemView.frame.minX - 4.0
                selectionGestureState = (startX, startX, itemView.bounds.width, itemId)
                onNeedsUpdate?(.spring(duration: 0.4))
            }
        case .changed:
            // 拖拽过程中更新 lens 位置
            if var state = selectionGestureState {
                state.currentX = state.startX + recognizer.translation(in: self).x
                if let itemId = itemId(at: recognizer.location(in: self)) {
                    state.itemId = itemId
                }
                selectionGestureState = state
                onNeedsUpdate?(.immediate)
            }
        case .ended, .cancelled:
            if let gestureState = selectionGestureState {
                selectionGestureState = nil
                if case .ended = recognizer.state {
                    guard let item = items.first(where: { $0.id == gestureState.itemId }) else { return }

                    // 检查是否为双击
                    var handledDoubleTap = false
                    if let pending = pendingDoubleTapItem {
                        pendingDoubleTapItem = nil
                        pending.timer.invalidate()
                        if pending.id == gestureState.itemId {
                            handledDoubleTap = true
                            item.doubleTapAction?()
                        }
                    }

                    if !handledDoubleTap {
                        if item.doubleTapAction != nil {
                            // 启动双击等待 timer（0.18s 窗口）
                            let timer = Foundation.Timer.scheduledTimer(withTimeInterval: 0.18, repeats: false) { [weak self] timer in
                                guard let self, let pending = self.pendingDoubleTapItem, pending.timer === timer else { return }
                                self.pendingDoubleTapItem = nil
                                self.overrideSelectedItemId = nil
                                self.onNeedsUpdate?(.spring(duration: 0.4))
                            }
                            overrideSelectedItemId = gestureState.itemId
                            item.action(false)
                            pendingDoubleTapItem = (gestureState.itemId, overrideSelectedItemId, timer)
                        } else {
                            // 无双击回调，直接触发选中
                            overrideSelectedItemId = gestureState.itemId
                            item.action(false)
                        }
                    }
                }
                onNeedsUpdate?(.spring(duration: 0.4))
            }
        default:
            break
        }
    }

    /// 根据触摸点查找最近的 item id。
    ///
    /// 优先精确命中，否则返回水平距离最近的 item。
    private func itemId(at point: CGPoint) -> AnyHashable? {
        var closest: (AnyHashable, CGFloat)?
        for (id, view) in itemContentViews {
            if view.frame.contains(point) { return id }
            let dist = abs(point.x - view.center.x)
            if closest == nil || dist < closest!.1 { closest = (id, dist) }
        }
        return closest?.0
    }
}

// MARK: - TabBarItemContentView

/// 单个 tab 项的内容视图，负责图标、标题和角标的渲染。
///
/// 每个 tab 同时存在两个实例：一个用于未选中态（放在 LiquidLens 的 contentView 中），
/// 一个用于选中态（放在 LiquidLens 的 selectedContentView 中）。
/// 两者通过 LiquidLens 的 mask 机制自动切换显示区域。
final class TabBarItemContentView: UIView {
    /// 上下文菜单的容器视图，长按时提取此视图用于预览。
    let contextContainerView = ContextExtractedContentContainingView()

    /// UIImage 模式的图标视图（与 animationIconView 互斥）。
    private var imageIconView: UIImageView?
    /// Lottie 动画模式的图标视图（与 imageIconView 互斥）。
    private var animationIconView: LottieIconView?
    /// 标题标签。
    private let titleLabel = UILabel()
    /// 角标视图。
    private var badgeView: TextBadgeView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(contextContainerView)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 测量 item 的自然宽度（不受容器约束）。
    ///
    /// 无标题时返回固定 48pt，有标题时根据文字宽度 + 左右 padding（10pt × 2）计算。
    static func measureWidth(item: TabBarItem) -> CGFloat {
        let title = item.title
        guard !title.isEmpty else { return 48.0 }
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10.0, weight: .semibold)]
        let titleSize = (title as NSString).boundingRect(with: CGSize(width: 200.0, height: 100.0), options: .usesLineFragmentOrigin, attributes: attrs, context: nil).size
        return ceil(titleSize.width) + 10.0 * 2.0
    }

    /// 更新 item 内容（图标、标题、角标）。
    ///
    /// 根据 `item.animation` 是否为 nil 自动切换 Lottie 动画模式和 UIImage 模式。
    /// 两种模式互斥：切换时会移除另一种模式的视图。
    func update(item: TabBarItem, theme: TabBarStyle, isSelected: Bool, availableSize: CGSize, transition: ViewTransition) {
        let hasTitle = !item.title.isEmpty

        // 图标：Lottie 动画模式 vs UIImage 模式
        if let animation = item.animation {
            // Lottie 模式：移除 UIImage 视图
            imageIconView?.removeFromSuperview()
            imageIconView = nil

            let iconView: LottieIconView
            if let existing = animationIconView {
                iconView = existing
            } else {
                iconView = LottieIconView()
                animationIconView = iconView
                if let bv = badgeView {
                    contextContainerView.contentView.insertSubview(iconView, belowSubview: bv)
                } else {
                    contextContainerView.contentView.addSubview(iconView)
                }
            }

            let iconSize = CGSize(width: 48.0, height: 48.0)
            let color = isSelected ? theme.selectedTextColor : theme.textColor
            iconView.update(name: animation.name, size: iconSize, color: color)
            // 有标题时图标上移，无标题时垂直居中
            let iconY = hasTitle ? -4.0 : floor((availableSize.height - iconSize.height) * 0.5)
            let iconFrame = CGRect(origin: CGPoint(x: floor((availableSize.width - iconSize.width) * 0.5), y: iconY), size: iconSize)
                .offsetBy(dx: animation.offset.x, dy: animation.offset.y)
            transition.setFrame(view: iconView, frame: iconFrame)
        } else {
            // UIImage 模式：移除 Lottie 视图
            animationIconView?.removeFromSuperview()
            animationIconView = nil

            let iconView: UIImageView
            if let existing = imageIconView {
                iconView = existing
            } else {
                iconView = UIImageView()
                iconView.contentMode = .center
                imageIconView = iconView
                if let bv = badgeView {
                    contextContainerView.contentView.insertSubview(iconView, belowSubview: bv)
                } else {
                    contextContainerView.contentView.addSubview(iconView)
                }
            }

            let img = (isSelected ? item.selectedImage : item.image)?.withRenderingMode(.alwaysTemplate)
            iconView.image = img
            iconView.tintColor = isSelected ? theme.selectedIconColor : theme.iconColor
            let imgSize = img?.size ?? .zero
            let iconY = hasTitle ? 3.0 : floor((availableSize.height - imgSize.height) * 0.5)
            let iconFrame = CGRect(origin: CGPoint(x: floor((availableSize.width - imgSize.width) * 0.5), y: iconY), size: imgSize)
            transition.setFrame(view: iconView, frame: iconFrame)
        }

        // 标题
        if hasTitle {
            let titleColor = isSelected ? theme.selectedTextColor : theme.textColor
            titleLabel.attributedText = NSAttributedString(string: item.title, attributes: [
                .font: UIFont.systemFont(ofSize: 10.0, weight: .semibold),
                .foregroundColor: titleColor,
            ])
            let titleSize = titleLabel.sizeThatFits(CGSize(width: availableSize.width, height: 100.0))
            let titleFrame = CGRect(origin: CGPoint(x: floor((availableSize.width - titleSize.width) * 0.5), y: availableSize.height - 8.0 - titleSize.height), size: titleSize)
            if titleLabel.superview == nil {
                contextContainerView.contentView.addSubview(titleLabel)
            }
            titleLabel.frame = titleFrame
            titleLabel.isHidden = false
        } else {
            titleLabel.isHidden = true
        }

        // 角标
        if let badgeText = item.badgeValue, !badgeText.isEmpty {
            let bv: TextBadgeView
            if let existing = badgeView {
                bv = existing
            } else {
                bv = TextBadgeView()
                badgeView = bv
                contextContainerView.contentView.addSubview(bv)
            }
            let badgeSize = bv.update(
                text: badgeText,
                font: UIFont.systemFont(ofSize: 13.0, weight: .regular),
                background: theme.badgeBackgroundColor,
                foreground: theme.badgeTextColor,
                insets: UIEdgeInsets(top: 0.0, left: 5.0, bottom: 1.0, right: 5.0),
                availableSize: CGSize(width: 100.0, height: 100.0),
                transition: transition
            )
            // 角标定位在图标右上方
            let contentWidth: CGFloat = 25.0
            let badgeFrame = CGRect(origin: CGPoint(x: floor(availableSize.width / 2.0) + contentWidth - badgeSize.width - 1.0, y: 5.0), size: badgeSize)
            transition.setFrame(view: bv, frame: badgeFrame)
        } else if let bv = badgeView {
            badgeView = nil
            bv.removeFromSuperview()
        }

        contextContainerView.frame = CGRect(origin: .zero, size: availableSize)
        contextContainerView.contentView.frame = CGRect(origin: .zero, size: availableSize)
    }

    /// 播放选中动画（Lottie 从头播放一次）。
    func playSelectionAnimation() {
        animationIconView?.playAnimation()
    }
}
