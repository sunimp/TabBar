//
//  RuntimeBridge.swift
//  TabBar
//
//  Created by Sun on 2026/4/21.
//

import UIKit

// MARK: - Spring 动画工厂

/// 创建标准 Spring 动画。
///
/// iOS 26+ 使用更轻量的弹簧参数（mass=1, stiffness=555, damping=47），
/// 并启用 120Hz 高帧率渲染。
/// 低版本使用较重的弹簧参数（mass=3, stiffness=1000, damping=500），固定 0.5s 时长。
func makeSpringAnimation(_ keyPath: String, duration: Double) -> CABasicAnimation {
    let animation = CASpringAnimation(keyPath: keyPath)
    if #available(iOS 26.0, *) {
        animation.mass = 1.0
        animation.stiffness = 555.027
        animation.damping = 47.118
        animation.duration = duration
        animation.allowsOverdamping = false
        animation.setValue(1_048_619, forKey: "highFrameRateReason")
        animation.preferredFrameRateRange = CAFrameRateRange(minimum: 80.0, maximum: 120.0, preferred: 120.0)
    } else {
        animation.mass = 3.0
        animation.stiffness = 1000.0
        animation.damping = 500.0
        animation.duration = 0.5
    }
    animation.timingFunction = CAMediaTimingFunction(name: .linear)
    return animation
}

/// 创建带弹跳效果的 Spring 动画。
///
/// 使用较大的 mass（5.0）和 stiffness（900.0）产生明显的弹跳感，
/// 时长自动根据 settlingDuration 计算。
func makeSpringBounceAnimation(_ keyPath: String, _ initialVelocity: CGFloat, _ damping: CGFloat) -> CASpringAnimation {
    let animation = CASpringAnimation(keyPath: keyPath)
    animation.mass = 5.0
    animation.stiffness = 900.0
    animation.damping = damping
    animation.initialVelocity = initialVelocity
    animation.duration = animation.settlingDuration
    animation.timingFunction = CAMediaTimingFunction(name: .linear)
    return animation
}

// MARK: - EffectSettingsContainerView

/// 亮度范围控制容器视图。
///
/// 通过私有 API `_setBackgroundLuminanceMin/Max:` 控制视觉效果的亮度范围。
/// 用于 `GlassBackgroundContainerView` 和 `GlassBackgroundView` 中，
/// 限制毛玻璃效果的亮度输出范围。
final class EffectSettingsContainerView: UIView {
    /// 最小亮度值，变化时自动更新私有 API。
    var lumaMin: CGFloat = 0.0 {
        didSet { if lumaMin != oldValue { updateSettings() } }
    }

    /// 最大亮度值，变化时自动更新私有 API。
    var lumaMax: CGFloat = 1.0 {
        didSet { if lumaMax != oldValue { updateSettings() } }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateSettings() {
        EffectSettingsBridge.setLuminanceRange(view: self, min: lumaMin, max: lumaMax)
    }
}
