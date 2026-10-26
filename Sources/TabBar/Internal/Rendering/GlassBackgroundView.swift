//
//  GlassBackgroundView.swift
//  TabBar
//
//  Created by Sun on 2026/3/30.
//

import UIKit

private final class ContentContainer: UIView {
    private let maskContentView: UIView

    init(maskContentView: UIView) {
        self.maskContentView = maskContentView

        super.init(frame: CGRect())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let result = super.hitTest(point, with: event) else {
            return nil
        }
        if result === self {
            if let gestureRecognizers = gestureRecognizers, !gestureRecognizers.isEmpty {
                return result
            }
            return nil
        }
        return result
    }

    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)

        if let subview = subview as? GlassBackgroundView.ContentView {
            maskContentView.addSubview(subview.tintMask)
        }
    }

    override func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)

        if let subview = subview as? GlassBackgroundView.ContentView {
            subview.tintMask.removeFromSuperview()
        }
    }
}

final class GlassBackgroundView: UIView {
    fileprivate protocol ContentView: UIView {
        var tintMask: UIView { get }
    }

    private final class ContentLayer: CALayer {
        var targetLayer: CALayer?

        override init() {
            super.init()
        }

        override init(layer: Any) {
            super.init(layer: layer)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var position: CGPoint {
            get {
                return super.position
            } set(value) {
                if let targetLayer = targetLayer {
                    targetLayer.position = value
                }
                super.position = value
            }
        }

        override var bounds: CGRect {
            get {
                return super.bounds
            } set(value) {
                if let targetLayer = targetLayer {
                    targetLayer.bounds = value
                }
                super.bounds = value
            }
        }

        override var anchorPoint: CGPoint {
            get {
                return super.anchorPoint
            } set(value) {
                if let targetLayer = targetLayer {
                    targetLayer.anchorPoint = value
                }
                super.anchorPoint = value
            }
        }

        override var anchorPointZ: CGFloat {
            get {
                return super.anchorPointZ
            } set(value) {
                if let targetLayer = targetLayer {
                    targetLayer.anchorPointZ = value
                }
                super.anchorPointZ = value
            }
        }

        override var opacity: Float {
            get {
                return super.opacity
            } set(value) {
                if let targetLayer = targetLayer {
                    targetLayer.opacity = value
                }
                super.opacity = value
            }
        }

        override var sublayerTransform: CATransform3D {
            get {
                return super.sublayerTransform
            } set(value) {
                if let targetLayer = targetLayer {
                    targetLayer.sublayerTransform = value
                }
                super.sublayerTransform = value
            }
        }

        override var transform: CATransform3D {
            get {
                return super.transform
            } set(value) {
                if let targetLayer = targetLayer {
                    targetLayer.transform = value
                }
                super.transform = value
            }
        }

        override func add(_ animation: CAAnimation, forKey key: String?) {
            if let targetLayer = targetLayer {
                targetLayer.add(animation, forKey: key)
            }

            super.add(animation, forKey: key)
        }

        override func removeAllAnimations() {
            if let targetLayer = targetLayer {
                targetLayer.removeAllAnimations()
            }

            super.removeAllAnimations()
        }

        override func removeAnimation(forKey: String) {
            if let targetLayer = targetLayer {
                targetLayer.removeAnimation(forKey: forKey)
            }

            super.removeAnimation(forKey: forKey)
        }
    }

    private final class ContentColorView: UIView, ContentView {
        override static var layerClass: AnyClass {
            return ContentLayer.self
        }

        let tintMask: UIView

        override init(frame _: CGRect) {
            tintMask = UIView()

            super.init(frame: CGRect())

            tintMask.tintColor = .black
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    final class ContentImageView: UIImageView, ContentView {
        override static var layerClass: AnyClass {
            return ContentLayer.self
        }

        private let tintImageView: UIImageView
        var tintMask: UIView {
            return tintImageView
        }

        override var image: UIImage? {
            didSet {
                tintImageView.image = image
            }
        }

        override var tintColor: UIColor? {
            didSet {
                if tintColor != oldValue {
                    MonochromaticBridge.setEnabled(self, enabled: tintColor != nil)
                }
            }
        }

        override init(frame _: CGRect) {
            tintImageView = UIImageView()

            super.init(frame: CGRect())

            tintImageView.tintColor = .black
        }

        override init(image: UIImage?) {
            tintImageView = UIImageView()

            super.init(image: image)

            tintImageView.image = image
            tintImageView.tintColor = .black
        }

        override init(image: UIImage?, highlightedImage: UIImage?) {
            tintImageView = UIImageView()

            super.init(image: image, highlightedImage: highlightedImage)

            tintImageView.image = image
            tintImageView.tintColor = .black
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    struct TintColor: Equatable {
        enum CustomStyle {
            case `default`
            case clear
        }

        enum Kind: Equatable {
            case panel
            case clear
            case custom(style: CustomStyle, color: UIColor)
        }

        let kind: Kind
        let innerColor: UIColor?
        let innerInset: CGFloat

        init(kind: Kind, innerColor: UIColor? = nil, innerInset: CGFloat = 3.0) {
            self.kind = kind
            self.innerColor = innerColor
            self.innerInset = innerInset
        }
    }

    private enum Shape: Equatable {
        case roundedRect(cornerRadius: CGFloat)
    }

    private final class ClippingShapeContext {
        let view: UIView

        private(set) var shape: Shape?

        init(view: UIView) {
            self.view = view
        }

        func update(shape: Shape, size _: CGSize, transition: ViewTransition) {
            self.shape = shape

            switch shape {
            case let .roundedRect(cornerRadius):
                transition.setCornerRadius(layer: view.layer, cornerRadius: cornerRadius)
            }
        }
    }

    private struct Params: Equatable {
        let shape: Shape
        let isDark: Bool
        let tintColor: TintColor
        let isInteractive: Bool
        let isVisible: Bool

        init(shape: Shape, isDark: Bool, tintColor: TintColor, isInteractive: Bool, isVisible: Bool) {
            self.shape = shape
            self.isDark = isDark
            self.tintColor = tintColor
            self.isInteractive = isInteractive
            self.isVisible = isVisible
        }
    }

    private let legacyView: LegacyGlassView?

    private let nativeView: UIVisualEffectView?
    private let nativeViewClippingContext: ClippingShapeContext?
    private let nativeParamsView: EffectSettingsContainerView?

    private let foregroundView: UIImageView?
    private let shadowView: UIImageView?

    private let maskContainerView: UIView
    private let maskContentView: UIView
    private let contentContainer: ContentContainer

    private var innerBackgroundView: UIView?

    var contentView: UIView {
        if let nativeView = nativeView {
            return nativeView.contentView
        } else {
            return contentContainer
        }
    }

    private var params: Params?

    static var useCustomGlassImpl: Bool = false

    override init(frame: CGRect) {
        if #available(iOS 26.0, *), !GlassBackgroundView.useCustomGlassImpl {
            legacyView = nil

            let glassEffect = UIGlassEffect(style: .regular)
            glassEffect.isInteractive = false
            let nativeView = UIVisualEffectView(effect: glassEffect)
            nativeViewClippingContext = ClippingShapeContext(view: nativeView)
            self.nativeView = nativeView

            let nativeParamsView = EffectSettingsContainerView(frame: CGRect())
            self.nativeParamsView = nativeParamsView

            nativeParamsView.addSubview(nativeView)

            foregroundView = nil
            shadowView = nil
        } else {
            legacyView = LegacyGlassView(frame: CGRect())
            nativeView = nil
            nativeViewClippingContext = nil
            nativeParamsView = nil
            foregroundView = UIImageView()

            shadowView = UIImageView()
        }

        maskContainerView = UIView()
        maskContainerView.backgroundColor = .white
        if let filter = CALayer.luminanceToAlpha() {
            maskContainerView.layer.filters = [filter]
        }

        maskContentView = UIView()
        maskContainerView.addSubview(maskContentView)

        contentContainer = ContentContainer(maskContentView: maskContentView)

        super.init(frame: frame)

        if let shadowView = shadowView {
            addSubview(shadowView)
        }
        if let nativeParamsView = nativeParamsView {
            addSubview(nativeParamsView)
        }
        if let legacyView = legacyView {
            addSubview(legacyView)
        }
        if let foregroundView = foregroundView {
            addSubview(foregroundView)
            foregroundView.mask = maskContainerView
        }
        addSubview(contentContainer)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !isUserInteractionEnabled {
            return nil
        }
        if isHidden {
            return nil
        }
        if alpha == 0.0 {
            return nil
        }
        if let nativeView = nativeView {
            if let result = nativeView.hitTest(convert(point, to: nativeView), with: event) {
                return result
            }
        } else {
            if let result = contentContainer.hitTest(convert(point, to: contentContainer), with: event) {
                return result
            }
        }
        return nil
    }

    func update(size: CGSize, cornerRadius: CGFloat, isDark: Bool, tintColor: TintColor, isInteractive: Bool = false, isVisible: Bool = true, transition: ViewTransition) {
        let shape: Shape = .roundedRect(cornerRadius: cornerRadius)
        let shadowInset: CGFloat = 32.0

        updateShapeAndSize(shape: shape, size: size, isDark: isDark, tintColor: tintColor, isVisible: isVisible, transition: transition)
        updateInnerBackground(tintColor: tintColor, size: size, transition: transition)
        updateAppearance(shape: shape, size: size, shadowInset: shadowInset, isDark: isDark, tintColor: tintColor, isInteractive: isInteractive, isVisible: isVisible, transition: transition)
        updateSubviewFrames(size: size, shadowInset: shadowInset, transition: transition)
    }

    // MARK: - 形状与尺寸

    /// 更新 native / legacy 视图的形状和尺寸。
    private func updateShapeAndSize(shape: Shape, size: CGSize, isDark: Bool, tintColor: TintColor, isVisible: Bool, transition: ViewTransition) {
        // 外观变化不依赖几何变化，否则同尺寸切换主题会保留旧 override。
        nativeView?.overrideUserInterfaceStyle = isDark ? .dark : .light
        if let nativeView = nativeView, let nativeViewClippingContext = nativeViewClippingContext, nativeView.bounds.size != size || nativeViewClippingContext.shape != shape {
            nativeViewClippingContext.update(shape: shape, size: size, transition: transition)
            if transition.animation.isImmediate {
                nativeView.frame = CGRect(origin: CGPoint(), size: size)
            } else {
                let nativeFrame = CGRect(origin: CGPoint(), size: size)
                transition.animateView {
                    nativeView.frame = nativeFrame
                }
            }
        }
        if let legacyView = legacyView {
            switch shape {
            case let .roundedRect(cornerRadius):
                let style: LegacyGlassView.Style
                switch tintColor.kind {
                case .panel:
                    style = .normal
                case .clear:
                    style = .clear
                case let .custom(styleValue, _):
                    switch styleValue {
                    case .clear:
                        style = .clear
                    case .default:
                        style = .normal
                    }
                }
                legacyView.update(size: size, cornerRadius: cornerRadius, style: style, transition: transition)
            }
            transition.setFrame(view: legacyView, frame: CGRect(origin: CGPoint(), size: size))
            transition.setAlpha(view: legacyView, alpha: isVisible ? 1.0 : 0.0)
        }
    }

    // MARK: - 内部背景

    /// 更新 innerBackgroundView（tintColor.innerColor 驱动）。
    private func updateInnerBackground(tintColor: TintColor, size: CGSize, transition: ViewTransition) {
        if let innerColor = tintColor.innerColor {
            let innerBackgroundFrame = CGRect(origin: CGPoint(), size: size).insetBy(dx: tintColor.innerInset, dy: tintColor.innerInset)
            let innerBackgroundRadius = min(innerBackgroundFrame.width, innerBackgroundFrame.height) * 0.5

            let innerBackgroundView: UIView
            var innerBackgroundTransition = transition
            var animateIn = false
            if let current = self.innerBackgroundView {
                innerBackgroundView = current
            } else {
                innerBackgroundView = UIView()
                innerBackgroundTransition = innerBackgroundTransition.withAnimation(.none)
                self.innerBackgroundView = innerBackgroundView
                contentView.insertSubview(innerBackgroundView, at: 0)

                innerBackgroundView.frame = innerBackgroundFrame
                innerBackgroundView.layer.cornerRadius = innerBackgroundRadius
                animateIn = true
            }

            innerBackgroundView.backgroundColor = innerColor
            innerBackgroundTransition.setFrame(view: innerBackgroundView, frame: innerBackgroundFrame)
            innerBackgroundTransition.setCornerRadius(layer: innerBackgroundView.layer, cornerRadius: innerBackgroundRadius)

            if animateIn {
                transition.animateAlpha(view: innerBackgroundView, from: 0.0, to: 1.0)
                transition.animateScale(view: innerBackgroundView, from: 0.001, to: 1.0)
            }
        } else if let innerBackgroundView = innerBackgroundView {
            self.innerBackgroundView = nil

            transition.setAlpha(view: innerBackgroundView, alpha: 0.0, completion: { [weak innerBackgroundView] _ in
                innerBackgroundView?.removeFromSuperview()
            })
            transition.setScale(view: innerBackgroundView, scale: 0.001)

            innerBackgroundView.removeFromSuperview()
        }
    }

    // MARK: - 外观效果

    /// 更新阴影、前景图片或 native glass effect。
    private func updateAppearance(shape: Shape, size _: CGSize, shadowInset: CGFloat, isDark: Bool, tintColor: TintColor, isInteractive: Bool, isVisible: Bool, transition: ViewTransition) {
        let params = Params(shape: shape, isDark: isDark, tintColor: tintColor, isInteractive: isInteractive, isVisible: isVisible)
        guard self.params != params else { return }
        self.params = params

        let outerCornerRadius: CGFloat
        switch shape {
        case let .roundedRect(cornerRadius):
            outerCornerRadius = cornerRadius
        }

        // 阴影
        if let shadowView = shadowView {
            let shadowInnerInset: CGFloat = 0.5
            shadowView.image = generateImage(CGSize(width: shadowInset * 2.0 + outerCornerRadius * 2.0, height: shadowInset * 2.0 + outerCornerRadius * 2.0), rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))

                context.setFillColor(UIColor.black.cgColor)
                context.setShadow(offset: CGSize(width: 0.0, height: 1.0), blur: 40.0, color: UIColor(white: 0.0, alpha: 0.04).cgColor)
                context.fillEllipse(in: CGRect(origin: CGPoint(x: shadowInset + shadowInnerInset, y: shadowInset + shadowInnerInset), size: CGSize(width: size.width - shadowInset * 2.0 - shadowInnerInset * 2.0, height: size.height - shadowInset * 2.0 - shadowInnerInset * 2.0)))

                context.setFillColor(UIColor.clear.cgColor)
                context.setBlendMode(.copy)
                context.fillEllipse(in: CGRect(origin: CGPoint(x: shadowInset + shadowInnerInset, y: shadowInset + shadowInnerInset), size: CGSize(width: size.width - shadowInset * 2.0 - shadowInnerInset * 2.0, height: size.height - shadowInset * 2.0 - shadowInnerInset * 2.0)))
            })?.stretchableImage(withLeftCapWidth: Int(shadowInset + outerCornerRadius), topCapHeight: Int(shadowInset + outerCornerRadius))
            transition.setAlpha(view: shadowView, alpha: isVisible ? 1.0 : 0.0)
        }

        // 前景（legacy）或 native glass effect
        if let foregroundView = foregroundView {
            updateLegacyForeground(foregroundView: foregroundView, outerCornerRadius: outerCornerRadius, shadowInset: shadowInset, isDark: isDark, tintColor: tintColor, isVisible: isVisible, transition: transition)
        } else {
            updateNativeGlassEffect(isDark: isDark, tintColor: tintColor, params: params, isVisible: isVisible, transition: transition)
        }
    }

    /// 更新 legacy 前景图片。
    private func updateLegacyForeground(foregroundView: UIImageView, outerCornerRadius: CGFloat, shadowInset: CGFloat, isDark: Bool, tintColor: TintColor, isVisible: Bool, transition: ViewTransition) {
        let fillColor: UIColor
        let borderWidthFactor: CGFloat
        switch tintColor.kind {
        case .panel:
            borderWidthFactor = 1.0
            if isDark {
                fillColor = UIColor(white: 1.0, alpha: 1.0).mixedWith(.black, alpha: 1.0 - 0.11).withAlphaComponent(0.85)
            } else {
                fillColor = UIColor(white: 1.0, alpha: 0.7)
            }
        case .clear:
            borderWidthFactor = 2.0
            fillColor = UIColor(white: 1.0, alpha: 0.0)
        case let .custom(style, color):
            fillColor = color
            switch style {
            case .clear:
                borderWidthFactor = 2.0
            case .default:
                borderWidthFactor = 1.0
            }
        }
        foregroundView.image = GlassBackgroundView.generateLegacyGlassImage(size: CGSize(width: outerCornerRadius * 2.0, height: outerCornerRadius * 2.0), inset: shadowInset, borderWidthFactor: borderWidthFactor, isDark: isDark, fillColor: fillColor)
        transition.setAlpha(view: foregroundView, alpha: isVisible ? 1.0 : 0.0)
    }

    /// 更新 native UIGlassEffect（iOS 26+）。
    private func updateNativeGlassEffect(isDark: Bool, tintColor: TintColor, params: Params, isVisible: Bool, transition: ViewTransition) {
        guard let nativeParamsView = nativeParamsView, let nativeView = nativeView else { return }
        if #available(iOS 26.0, *) {
            var glassEffect: UIGlassEffect?

            if isVisible {
                let glassEffectValue: UIGlassEffect
                switch tintColor.kind {
                case .panel:
                    if isDark {
                        glassEffectValue = UIGlassEffect(style: .regular)
                        glassEffectValue.tintColor = UIColor(white: 1.0, alpha: 0.025)
                    } else {
                        glassEffectValue = UIGlassEffect(style: .regular)
                        glassEffectValue.tintColor = UIColor(white: 1.0, alpha: 0.1)
                    }
                case let .custom(style, color):
                    switch style {
                    case .default:
                        glassEffectValue = UIGlassEffect(style: .regular)
                        glassEffectValue.tintColor = color
                    case .clear:
                        glassEffectValue = UIGlassEffect(style: .clear)
                        glassEffectValue.tintColor = color
                    }
                case .clear:
                    glassEffectValue = UIGlassEffect(style: .clear)
                    if isDark {
                        glassEffectValue.tintColor = UIColor(white: 0.0, alpha: 0.28)
                    } else {
                        glassEffectValue.tintColor = nil
                    }
                }
                glassEffectValue.isInteractive = params.isInteractive
                glassEffect = glassEffectValue
            }

            if glassEffect == nil {
                if nativeView.effect is UIGlassEffect {
                    if #available(iOS 26.1, *) {
                        if transition.animation.isImmediate {
                            nativeView.effect = nil
                        } else {
                            transition.animateView {
                                nativeView.effect = nil
                            }
                        }
                    } else {
                        if transition.animation.isImmediate {
                            nativeView.effect = UIVisualEffect()
                        } else {
                            transition.animateView {
                                nativeView.effect = UIVisualEffect()
                            }
                        }
                    }
                }
            } else {
                if transition.animation.isImmediate {
                    nativeView.effect = glassEffect
                } else {
                    if let glassEffect, let currentEffect = nativeView.effect as? UIGlassEffect, currentEffect.tintColor == glassEffect.tintColor, currentEffect.isInteractive == glassEffect.isInteractive {
                    } else {
                        transition.animateView {
                            nativeView.effect = glassEffect
                        }
                    }
                }
            }

            if isDark {
                nativeParamsView.lumaMin = 0.0
                nativeParamsView.lumaMax = 0.15
            } else {
                nativeParamsView.lumaMin = 0.8
                nativeParamsView.lumaMax = 0.801
            }
        }
    }

    // MARK: - 子视图 Frame

    /// 更新所有辅助子视图的 frame。
    private func updateSubviewFrames(size: CGSize, shadowInset: CGFloat, transition: ViewTransition) {
        if let nativeParamsView = nativeParamsView {
            transition.setFrame(view: nativeParamsView, frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: size))
        }
        transition.setFrame(view: maskContainerView, frame: CGRect(origin: CGPoint(), size: CGSize(width: size.width + shadowInset * 2.0, height: size.height + shadowInset * 2.0)))
        transition.setFrame(view: maskContentView, frame: CGRect(origin: CGPoint(x: shadowInset, y: shadowInset), size: size))
        if let foregroundView = foregroundView {
            transition.setFrame(view: foregroundView, frame: CGRect(origin: CGPoint(), size: size).insetBy(dx: -shadowInset, dy: -shadowInset))
        }
        if let shadowView = shadowView {
            transition.setFrame(view: shadowView, frame: CGRect(origin: CGPoint(), size: size).insetBy(dx: -shadowInset, dy: -shadowInset))
        }
        transition.setFrame(view: contentContainer, frame: CGRect(origin: CGPoint(), size: size))
    }
}
