//
//  LottieIconView.swift
//  TabBar
//
//  Created by Sun on 2026/4/21.
//

import Lottie
import UIKit

/// Lottie 动画图标视图，用于 TabBar 中的动画图标显示。
///
/// 支持按名称加载 Lottie 动画资源，动态着色，以及选中时播放动画。
/// 使用主线程渲染引擎以确保与 CALayer 动画系统兼容。
final class LottieIconView: UIView {
    /// 动画初始位置。
    enum StartingPosition {
        /// 从第一帧开始。
        case begin
        /// 从最后一帧开始（默认，显示静态的结束状态）。
        case end
    }

    /// 内部 Lottie 动画视图。
    private var animationView: LottieAnimationView?
    /// 当前加载的动画资源名称，用于避免重复加载。
    private var currentName: String?
    /// 当前应用的着色颜色，用于避免重复设置 ColorValueProvider。
    private var currentColor: UIColor?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 更新动画内容。
    ///
    /// 当 `name` 变化时重新加载动画资源；当 `color` 变化时更新着色。
    /// 动画资源优先从 `Bundle.main` 查找，其次从 SPM 默认 bundle 查找。
    func update(name: String, size: CGSize, color: UIColor, startingPosition: StartingPosition = .end, loop: Bool = false) {
        if currentName != name {
            currentName = name
            currentColor = nil
            animationView?.removeFromSuperview()
            animationView = nil

            if let animation = LottieAnimation.named(name, bundle: Bundle.main) ?? LottieAnimation.named(name) {
                let view = LottieAnimationView(
                    animation: animation,
                    configuration: LottieConfiguration(renderingEngine: .mainThread)
                )
                view.loopMode = loop ? .loop : .playOnce
                view.contentMode = .scaleAspectFit
                view.isUserInteractionEnabled = false
                view.frame = CGRect(origin: .zero, size: size)
                view.currentProgress = startingPosition == .end ? 1.0 : 0.0
                addSubview(view)
                animationView = view
            }
        }

        if currentColor != color {
            currentColor = color
            animationView?.setValueProvider(ColorValueProvider(color.lottieColorValue), keypath: AnimationKeypath(keypath: "**.Color"))
        }

        animationView?.frame = CGRect(origin: .zero, size: size)
    }

    /// 从头播放一次动画（用于 tab 选中时的视觉反馈）。
    func playAnimation() {
        animationView?.currentProgress = 0
        animationView?.play()
    }
}
