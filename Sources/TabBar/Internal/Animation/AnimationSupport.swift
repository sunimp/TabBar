//
//  AnimationSupport.swift
//  TabBar
//
//  Created by Sun on 2026/4/21.
//

import UIKit

// MARK: - 模拟器动画速度系数

#if targetEnvironment(simulator)
    /// 模拟器私有函数，返回动画拖拽系数（Slow Animations 开启时 > 1）。
    @_silgen_name("UIAnimationDragCoefficient") private func UIAnimationDragCoefficient() -> Float
#endif

/// 私有 Spring 动画 timing function 名称（CAAnimationUtilsSpringCurve）。
let kCAMediaTimingFunctionSpring = SpringTimingBridge.springCurve
/// 私有自定义 Spring 动画 timing function 前缀（CAAnimationUtilsSpringCustomCurve）。
let kCAMediaTimingFunctionCustomSpringPrefix = SpringTimingBridge.springCustomCurvePrefix

// MARK: - CALayerAnimationDelegate

/// CAAnimation 的 delegate 封装，用于在动画完成时执行回调。
///
/// 通过 keyPath 匹配确保回调只响应对应的动画，避免同一 layer 上多个动画的回调混淆。
@objc private class CALayerAnimationDelegate: NSObject, CAAnimationDelegate {
    private let keyPath: String?
    var completion: ((Bool) -> Void)?

    init(animation: CAAnimation, completion: ((Bool) -> Void)?) {
        if let animation = animation as? CABasicAnimation {
            keyPath = animation.keyPath
        } else {
            keyPath = nil
        }
        self.completion = completion
        super.init()
    }

    @objc func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let anim = anim as? CABasicAnimation, anim.keyPath != keyPath {
            return
        }
        if let completion = completion {
            completion(flag)
            self.completion = nil
        }
    }
}

/// CAAnimation 的 completion 回调扩展。
///
/// 通过关联的 `CALayerAnimationDelegate` 实现，设置 completion 时自动创建 delegate。
extension CAAnimation {
    var completion: ((Bool) -> Void)? {
        get {
            (delegate as? CALayerAnimationDelegate)?.completion
        }
        set {
            if let delegate = delegate as? CALayerAnimationDelegate {
                delegate.completion = newValue
            } else {
                delegate = CALayerAnimationDelegate(animation: self, completion: newValue)
            }
        }
    }
}

extension UIView {
    /// 动画时长系数。模拟器开启 Slow Animations 时返回拖拽系数，真机始终为 1.0。
    static var animationDurationFactor: Double {
        #if targetEnvironment(simulator)
            Double(UIAnimationDragCoefficient())
        #else
            1.0
        #endif
    }
}

/// 为动画设置 ProMotion 高帧率（120Hz）。
///
/// 仅在 Info.plist 中声明了 `CADisableMinimumFrameDurationOnPhone = true` 时生效。
/// opacity 动画不需要高帧率，跳过处理。
func adjustFrameRate(animation: CAAnimation) {
    let maxFps = Float(CADisableMinimumFrameDurationOnPhone ? 120.0 : 60.0)
    guard maxFps > 61.0 else { return }
    if let animation = animation as? CABasicAnimation, animation.keyPath == "opacity" {
        return
    }
    animation.preferredFrameRateRange = CAFrameRateRange(minimum: 30.0, maximum: maxFps, preferred: maxFps)
}

/// 是否支持 ProMotion（120Hz）。
private let CADisableMinimumFrameDurationOnPhone: Bool = Bundle.main.object(forInfoDictionaryKey: "CADisableMinimumFrameDurationOnPhone") as? Bool ?? false

extension UIColor {
    /// 提取颜色的 alpha 分量（兼容 RGB 和灰度色彩空间）。
    var alpha: CGFloat {
        var alpha: CGFloat = 0.0
        if getRed(nil, green: nil, blue: nil, alpha: &alpha) {
            return alpha
        } else if getWhite(nil, alpha: &alpha) {
            return alpha
        } else {
            return 0.0
        }
    }
}

package extension UIColor {
    /// 将当前颜色与另一颜色按比例混合。
    ///
    /// - Parameters:
    ///   - other: 目标颜色。
    ///   - alpha: 混合比例（0.0 = 完全当前颜色，1.0 = 完全目标颜色）。
    func mixedWith(_ other: UIColor, alpha: CGFloat) -> UIColor {
        let alpha = min(1.0, max(0.0, alpha))
        let oneMinusAlpha = 1.0 - alpha

        var r1: CGFloat = 0.0, r2: CGFloat = 0.0
        var g1: CGFloat = 0.0, g2: CGFloat = 0.0
        var b1: CGFloat = 0.0, b2: CGFloat = 0.0
        var a1: CGFloat = 0.0, a2: CGFloat = 0.0

        if getRed(&r1, green: &g1, blue: &b1, alpha: &a1),
           other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        {
            return UIColor(
                red: r1 * oneMinusAlpha + r2 * alpha,
                green: g1 * oneMinusAlpha + g2 * alpha,
                blue: b1 * oneMinusAlpha + b2 * alpha,
                alpha: a1 * oneMinusAlpha + a2 * alpha
            )
        }
        return self
    }
}

// MARK: - CALayer Filter 便捷方法

package extension CALayer {
    static func blur() -> NSObject? {
        CAFilterBridge.makeGaussianBlur()
    }

    static func luminanceToAlpha() -> NSObject? {
        CAFilterBridge.makeLuminanceToAlpha()
    }

    static func variableBlur() -> NSObject? {
        CAFilterBridge.makeVariableBlur()
    }
}
