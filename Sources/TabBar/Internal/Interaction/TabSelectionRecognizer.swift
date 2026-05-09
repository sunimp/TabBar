//
//  TabSelectionRecognizer.swift
//  TabBar
//
//  Created by Sun on 2026/3/30.
//

import UIKit

/// 自定义 Tab 选择手势识别器。
///
/// 与标准 `UITapGestureRecognizer` 不同，此手势在 `touchesBegan` 时立即进入 `.began` 状态，
/// 支持按下 → 拖拽 → 松手的连续交互流程。
///
/// 特性：
/// - 不延迟 touches 传递（`delaysTouchesBegan = false`）
/// - 提供 `translation(in:)` 方法计算拖拽偏移量
/// - 触摸移动时持续更新 `.changed` 状态
final class TabSelectionRecognizer: UIGestureRecognizer {
    /// 触摸起始位置。
    private var initialLocation: CGPoint?
    /// 当前触摸位置。
    private var currentLocation: CGPoint?

    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)

        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }

    override func reset() {
        super.reset()

        initialLocation = nil
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        if initialLocation == nil {
            initialLocation = touches.first?.location(in: view)
        }
        currentLocation = initialLocation

        state = .began
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)

        state = .ended
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)

        state = .cancelled
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        currentLocation = touches.first?.location(in: view)

        state = .changed
    }

    /// 计算从触摸起始位置到当前位置的偏移量。
    func translation(in _: UIView?) -> CGPoint {
        if let initialLocation = initialLocation, let currentLocation = currentLocation {
            return CGPoint(x: currentLocation.x - initialLocation.x, y: currentLocation.y - initialLocation.y)
        }
        return CGPoint()
    }
}
