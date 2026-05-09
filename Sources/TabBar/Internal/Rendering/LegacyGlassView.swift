//
//  LegacyGlassView.swift
//  TabBar
//
//  Created by Sun on 2026/3/30.
//

import UIKit

/// 禁用隐式动画的 null action 单例。
private let nullAction = NSNull()

/// CALayer delegate，返回 null action 以禁用所有隐式动画。
private final class BackdropLayerDelegate: NSObject, CALayerDelegate {
    func action(for _: CALayer, forKey _: String) -> CAAction? {
        nullAction
    }
}

/// iOS 26 以下的毛玻璃背景视图（Legacy 实现）。
///
/// 通过私有 `CABackdropLayer` 实现实时背景捕获，配合高斯模糊 CAFilter 产生毛玻璃效果。
/// iOS 26+ 使用 `UIGlassEffect` 替代，此视图仅在低版本使用。
final class LegacyGlassView: UIView {
    /// 模糊样式。
    enum Style {
        /// 正常模糊（半径 2pt），用于 panel 和 default 风格。
        case normal
        /// 清透模糊（半径 6pt），用于 clear 风格。
        case clear
    }

    /// 参数缓存，用于避免重复更新。
    private struct Params: Equatable {
        let size: CGSize
        let cornerRadius: CGFloat
        let style: Style
    }

    private var params: Params?

    /// 私有 CABackdropLayer，实时捕获下方视图内容。
    private let backdropLayer: CALayer?
    /// 禁用隐式动画的 delegate。
    private let backdropLayerDelegate: BackdropLayerDelegate

    override init(frame: CGRect) {
        backdropLayerDelegate = BackdropLayerDelegate()
        backdropLayer = CAFilterBridge.makeBackdropLayer()

        super.init(frame: frame)

        layer.cornerCurve = .circular
        clipsToBounds = true

        if let backdropLayer {
            layer.addSublayer(backdropLayer)
            backdropLayer.delegate = backdropLayerDelegate
            CAFilterBridge.setBackdropScale(backdropLayer, scale: 1.0)
            backdropLayer.rasterizationScale = 1.0
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 更新尺寸、圆角和模糊样式。
    ///
    /// 样式变化时重新创建高斯模糊 CAFilter 并设置模糊半径。
    func update(size: CGSize, cornerRadius: CGFloat, style: Style, transition: ViewTransition) {
        let params = Params(size: size, cornerRadius: cornerRadius, style: style)
        let previousParams = self.params
        guard self.params != params else { return }
        self.params = params

        guard let backdropLayer else { return }

        if previousParams?.style != style {
            if let blurFilter = CAFilterBridge.makeGaussianBlur() {
                let radius: NSNumber = style == .clear ? 6.0 : 2.0
                blurFilter.setValue(radius, forKey: CAFilterInputKey.radius)
                backdropLayer.filters = [blurFilter]
            }
        }

        transition.setCornerRadius(layer: layer, cornerRadius: cornerRadius)
        transition.setFrame(layer: backdropLayer, frame: CGRect(origin: CGPoint(), size: size))
    }
}
