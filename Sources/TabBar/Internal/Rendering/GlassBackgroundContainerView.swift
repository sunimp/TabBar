//
//  GlassBackgroundContainerView.swift
//  TabBar
//
//  Created by Sun on 2026/4/21.
//

import UIKit

/// 毛玻璃背景的外层容器视图。
///
/// iOS 26+ 使用 `UIGlassContainerEffect`（系统原生玻璃容器效果），
/// 低版本回退到普通 UIView 作为内容容器。
///
/// 此视图作为 `TabBarContentView` 的最底层背景，
/// 其 `contentView` 用于承载 `containerView` 和 `LiquidLensView`。
final class GlassBackgroundContainerView: UIView {
    /// 低版本的普通内容容器。
    private final class ContentView: UIView {}

    /// 低版本容器（iOS < 26）。
    private let legacyView: ContentView?
    /// 亮度范围控制容器（iOS 26+）。
    private let nativeParamsView: EffectSettingsContainerView?
    /// 系统玻璃效果视图（iOS 26+）。
    private let nativeView: UIVisualEffectView?

    /// 内容容器视图。iOS 26+ 返回 UIVisualEffectView 的 contentView，低版本返回普通 UIView。
    var contentView: UIView {
        if let nativeView {
            return nativeView.contentView
        } else {
            return legacyView!
        }
    }

    override init(frame: CGRect) {
        if #available(iOS 26.0, *), !GlassBackgroundView.useCustomGlassImpl {
            let effect = UIGlassContainerEffect()
            effect.spacing = 7.0
            let nativeView = UIVisualEffectView(effect: effect)
            self.nativeView = nativeView

            let nativeParamsView = EffectSettingsContainerView(frame: CGRect())
            self.nativeParamsView = nativeParamsView
            nativeParamsView.addSubview(nativeView)

            legacyView = nil
        } else {
            nativeView = nil
            nativeParamsView = nil
            legacyView = ContentView()
        }

        super.init(frame: frame)

        if let nativeParamsView {
            addSubview(nativeParamsView)
        } else if let legacyView {
            addSubview(legacyView)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        if subview !== nativeParamsView, subview !== legacyView {
            assertionFailure()
        }
    }

    /// 自定义 hitTest：只响应 contentView 内子视图的触摸，容器本身不拦截事件。
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !alpha.isZero, !isHidden, isUserInteractionEnabled else { return nil }

        for view in contentView.subviews.reversed() {
            if let result = view.hitTest(convert(point, to: view), with: event), result.isUserInteractionEnabled {
                return result
            }
        }

        guard let result = contentView.hitTest(point, with: event), result !== contentView else {
            return nil
        }
        return result
    }

    /// 更新尺寸和暗色模式。
    ///
    /// iOS 26+：设置亮度范围参数（暗色模式 0~0.15，亮色模式 0.8~0.801）。
    /// 低版本：仅更新 frame。
    func update(size: CGSize, isDark: Bool, transition: ViewTransition) {
        if let nativeParamsView, let nativeView {
            nativeView.overrideUserInterfaceStyle = isDark ? .dark : .light

            if isDark {
                nativeParamsView.lumaMin = 0.0
                nativeParamsView.lumaMax = 0.15
            } else {
                nativeParamsView.lumaMin = 0.8
                nativeParamsView.lumaMax = 0.801
            }
            transition.setFrame(view: nativeParamsView, frame: CGRect(origin: .zero, size: size))
            transition.animateView {
                nativeView.frame = CGRect(origin: .zero, size: size)
            }
        } else if let legacyView {
            transition.setFrame(view: legacyView, frame: CGRect(origin: .zero, size: size))
        }
    }
}
