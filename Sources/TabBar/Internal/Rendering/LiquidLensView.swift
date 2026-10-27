//
//  LiquidLensView.swift
//  TabBar
//
//  Created by Sun on 2026/3/30.
//

import UIKit

private final class RestingBackgroundView: UIVisualEffectView {
    var isDark: Bool?

    static func colorMatrix(isDark: Bool) -> [Float32] {
        if isDark {
            return [1.082, -0.113, -0.011, 0.0, 0.135, -0.034, 1.003, -0.011, 0.0, 0.135, -0.034, -0.113, 1.105, 0.0, 0.135, 0.0, 0.0, 0.0, 1.0, 0.0]
        } else {
            return [1.185, -0.05, -0.005, 0.0, -0.2, -0.015, 1.15, -0.005, 0.0, -0.2, -0.015, -0.05, 1.195, 0.0, -0.2, 0.0, 0.0, 0.0, 1.0, 0.0]
        }
    }

    init() {
        let effect = UIBlurEffect(style: .light)
        super.init(effect: effect)

        for subview in subviews where VisualEffectBridge.isEffectSubview(subview) {
            subview.isHidden = true
        }

        clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(isDark: Bool) {
        if self.isDark == isDark {
            return
        }
        self.isDark = isDark

        if let sublayer = layer.sublayers?[0], sublayer.filters != nil {
            sublayer.backgroundColor = nil
            sublayer.isOpaque = false

            if let filter = CAFilterBridge.makeColorMatrix() {
                var matrix: [Float32] = RestingBackgroundView.colorMatrix(isDark: isDark)
                filter.setValue(NSValue(bytes: &matrix, objCType: "{CAColorMatrix=ffffffffffffffffffff}"), forKey: CAFilterInputKey.colorMatrix)
                sublayer.filters = [filter]
                sublayer.setValue(1.0, forKey: "scale")
            }
        }
    }
}

final class LiquidLensView: UIView {
    enum Kind {
        case externalContainer
        case builtinContainer
        case noContainer
    }

    private struct Params: Equatable {
        var size: CGSize
        var cornerRadius: CGFloat?
        var selectionOrigin: CGPoint
        var selectionSize: CGSize
        var inset: CGFloat
        var liftedInset: CGFloat
        var outerInsets: UIEdgeInsets
        var isDark: Bool
        var isLifted: Bool
        var isCollapsed: Bool

        init(size: CGSize, cornerRadius: CGFloat?, selectionOrigin: CGPoint, selectionSize: CGSize, inset: CGFloat, liftedInset: CGFloat, outerInsets: UIEdgeInsets, isDark: Bool, isLifted: Bool, isCollapsed: Bool) {
            self.size = size
            self.cornerRadius = cornerRadius
            self.selectionOrigin = selectionOrigin
            self.selectionSize = selectionSize
            self.inset = inset
            self.liftedInset = liftedInset
            self.outerInsets = outerInsets
            self.isLifted = isLifted
            self.isDark = isDark
            self.isCollapsed = isCollapsed
        }
    }

    private struct LensParams: Equatable {
        var baseFrame: CGRect
        var inset: CGFloat
        var liftedInset: CGFloat
        var isLifted: Bool

        init(baseFrame: CGRect, inset: CGFloat, liftedInset: CGFloat, isLifted: Bool) {
            self.baseFrame = baseFrame
            self.inset = inset
            self.liftedInset = liftedInset
            self.isLifted = isLifted
        }
    }

    private let containerView: UIView
    private let backgroundContainer: GlassBackgroundContainerView?
    private let genericBackgroundContainer: UIView?
    private let backgroundView: GlassBackgroundView?
    private var lensView: UIView?
    private let liftedContainerView: UIView
    let contentView: UIView
    private let restingBackgroundView: RestingBackgroundView

    private var legacySelectionView: GlassBackgroundView.ContentImageView?
    private var legacyContentMaskView: UIView?
    private var legacyContentMaskBlobView: UIImageView?
    private var legacyLiftedContentBlobMaskView: UIImageView?

    var selectedContentView: UIView {
        return liftedContainerView
    }

    private var params: Params?
    private var appliedLensParams: LensParams?
    private var isApplyingLensParams: Bool = false
    private var pendingLensParams: LensParams?

    private var liftedDisplayLink: SharedDisplayLinkDriver.Link?

    private var selectionOrigin: CGPoint? {
        return params?.selectionOrigin
    }

    private var selectionSize: CGSize? {
        return params?.selectionSize
    }

    private var isAnimating: Bool = false

    init(kind: Kind) {
        containerView = UIView()

        switch kind {
        case .builtinContainer:
            backgroundContainer = GlassBackgroundContainerView()
            genericBackgroundContainer = nil
        case .externalContainer, .noContainer:
            backgroundContainer = nil
            genericBackgroundContainer = UIView()
        }

        if case .noContainer = kind {
            backgroundView = nil
        } else {
            backgroundView = GlassBackgroundView()
        }

        contentView = UIView()
        liftedContainerView = UIView()

        restingBackgroundView = RestingBackgroundView()

        super.init(frame: CGRect())

        if let backgroundContainer = backgroundContainer {
            addSubview(backgroundContainer)
            if let backgroundView = backgroundView {
                backgroundContainer.contentView.addSubview(backgroundView)
                backgroundView.contentView.addSubview(containerView)
            }
        } else if let genericBackgroundContainer = genericBackgroundContainer {
            addSubview(genericBackgroundContainer)
            if let backgroundView = backgroundView {
                genericBackgroundContainer.addSubview(backgroundView)
                backgroundView.contentView.addSubview(containerView)
            } else {
                genericBackgroundContainer.addSubview(containerView)
            }
        }
        containerView.isUserInteractionEnabled = false

        if #available(iOS 26.0, *) {
            lensView = LiquidLensBridge.makeLensView(restingBackground: UIView())
        }

        if let lensView = lensView {
            if let backgroundContainer = backgroundContainer {
                backgroundContainer.layer.zPosition = 1
            } else if let genericBackgroundContainer = genericBackgroundContainer {
                genericBackgroundContainer.layer.zPosition = 1
            }
            lensView.layer.zPosition = 10.0

            liftedContainerView.addSubview(restingBackgroundView)

            containerView.addSubview(liftedContainerView)
            containerView.addSubview(lensView)
            containerView.addSubview(contentView)

            if let backgroundContainer = backgroundContainer {
                LiquidLensBridge.setLiftedContainerView(lensView, view: backgroundContainer.contentView)
            } else if let genericBackgroundContainer = genericBackgroundContainer {
                LiquidLensBridge.setLiftedContainerView(lensView, view: genericBackgroundContainer)
            }
            LiquidLensBridge.setLiftedContentView(lensView, view: liftedContainerView)
            LiquidLensBridge.setOverridePunchoutView(lensView, view: contentView)
            LiquidLensBridge.setLiftedContentMode(lensView, mode: 1)
            LiquidLensBridge.setStyle(lensView, style: 1)
            LiquidLensBridge.setWarpsContentBelow(lensView, warps: true)
            LiquidLensBridge.setRestingBackgroundColor(lensView, color: UIColor(white: 0.0, alpha: 0.1))
        } else {
            let legacySelectionView = GlassBackgroundView.ContentImageView()
            self.legacySelectionView = legacySelectionView
            if let backgroundView = backgroundView {
                backgroundView.contentView.insertSubview(legacySelectionView, at: 0)
            } else {
                containerView.insertSubview(legacySelectionView, at: 0)
            }

            let legacyContentMaskView = UIView()
            legacyContentMaskView.backgroundColor = .white
            self.legacyContentMaskView = legacyContentMaskView
            contentView.mask = legacyContentMaskView

            if let filter = CALayer.luminanceToAlpha() {
                legacyContentMaskView.layer.filters = [filter]
            }

            let legacyContentMaskBlobView = UIImageView()
            self.legacyContentMaskBlobView = legacyContentMaskBlobView
            legacyContentMaskView.addSubview(legacyContentMaskBlobView)

            containerView.addSubview(contentView)

            let legacyLiftedContentBlobMaskView = UIImageView()
            self.legacyLiftedContentBlobMaskView = legacyLiftedContentBlobMaskView
            liftedContainerView.mask = legacyLiftedContentBlobMaskView

            containerView.addSubview(liftedContainerView)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setLiftedContainer(view: UIView) {
        guard let lensView else { return }
        LiquidLensBridge.setLiftedContainerView(lensView, view: view)
    }

    func update(size: CGSize, cornerRadius: CGFloat? = nil, selectionOrigin: CGPoint, selectionSize: CGSize, inset: CGFloat, liftedInset: CGFloat = 4.0, outerInsets: UIEdgeInsets = .zero, isDark: Bool, isLifted: Bool, isCollapsed: Bool = false, transition: ViewTransition) {
        let params = Params(size: size, cornerRadius: cornerRadius, selectionOrigin: selectionOrigin, selectionSize: selectionSize, inset: inset, liftedInset: liftedInset, outerInsets: outerInsets, isDark: isDark, isLifted: isLifted, isCollapsed: isCollapsed)
        if self.params == params {
            return
        }
        update(params: params, transition: transition)
    }

    private func update(transition: ViewTransition) {
        guard let params = params else {
            return
        }
        update(params: params, transition: transition)
    }

    private func updateLens(params: LensParams, transition: ViewTransition) {
        guard let lensView = lensView else {
            return
        }

        if isApplyingLensParams {
            pendingLensParams = params
            return
        }
        isApplyingLensParams = true
        let previousParams = appliedLensParams
        appliedLensParams = params

        if previousParams?.isLifted != params.isLifted {
            isAnimating = true

            var shouldScheduleUpdate = false
            var didProcessUpdate = false
            pendingLensParams = params
            if let lensView = self.lensView {
                LiquidLensBridge.setLifted(lensView, lifted: params.isLifted, animated: !transition.animation.isImmediate, alongside: { [weak self] in
                    guard let self else { return }
                    let liftedInset: CGFloat = params.isLifted ? params.liftedInset : (-params.inset)
                    lensView.bounds = CGRect(origin: CGPoint(), size: CGSize(width: params.baseFrame.width + liftedInset * 2.0, height: params.baseFrame.height + liftedInset * 2.0))
                    didProcessUpdate = true
                    if shouldScheduleUpdate {
                        DispatchQueue.main.async { [weak self] in
                            guard let self, let pendingLensParams = self.pendingLensParams else { return }
                            self.isApplyingLensParams = false
                            self.pendingLensParams = nil
                            self.updateLens(params: pendingLensParams, transition: transition)
                        }
                    }
                }, completion: { [weak self] in
                    guard let self else { return }
                    if !self.isApplyingLensParams {
                        self.isAnimating = false
                    }
                })
            }
            if didProcessUpdate {
                transition.animateView {
                    lensView.center = CGPoint(x: params.baseFrame.midX, y: params.baseFrame.midY)
                }
                pendingLensParams = nil
                isApplyingLensParams = false
            } else {
                shouldScheduleUpdate = true
            }
        } else {
            let liftedInset: CGFloat = params.isLifted ? params.liftedInset : (-params.inset)
            let lensBounds = CGRect(origin: CGPoint(), size: CGSize(width: params.baseFrame.width + liftedInset * 2.0, height: params.baseFrame.height + liftedInset * 2.0))
            let lensCenter = CGPoint(x: params.baseFrame.midX, y: params.baseFrame.midY)

            let previousBounds: CGRect = lensView.bounds
            transition.animateView {
                lensView.bounds = lensBounds
            }

            lensView.layer.removeAllAnimations()
            lensView.bounds = lensBounds

            if !transition.animation.isImmediate {
                isAnimating = true
            }
            transition.setPosition(view: lensView, position: lensCenter, completion: { [weak self] flag in
                guard let self, flag else {
                    return
                }
                if !self.isApplyingLensParams {
                    self.isAnimating = false
                }
            })
            // No idea why
            transition.animatePosition(layer: lensView.layer, from: CGPoint(x: (lensBounds.width - previousBounds.width) * 0.5, y: 0.0), to: CGPoint(), additive: true)

            isApplyingLensParams = false
        }
    }

    private func updateLiftedLensPosition() {
        // Without this, the lens won't update its bouncing animations unless it's being moved
        if isApplyingLensParams {
            return
        }
        guard let lensView = lensView else {
            return
        }
        guard let params = appliedLensParams else {
            return
        }
        lensView.center = CGPoint(x: params.baseFrame.midX, y: params.baseFrame.midY)
    }

    private func update(params: Params, transition: ViewTransition) {
        let isFirstTime = self.params == nil
        let transition: ViewTransition = isFirstTime ? .immediate : transition

        self.params = params

        transition.setFrame(view: containerView, frame: CGRect(origin: CGPoint(), size: params.size))

        if let backgroundContainer = backgroundContainer {
            transition.setFrame(view: backgroundContainer, frame: CGRect(origin: CGPoint(), size: params.size))
            backgroundContainer.update(size: params.size, isDark: params.isDark, transition: transition)
        } else if let genericBackgroundContainer = genericBackgroundContainer {
            transition.setFrame(view: genericBackgroundContainer, frame: CGRect(origin: CGPoint(), size: params.size))
        }

        if let backgroundView = backgroundView {
            transition.setFrame(view: backgroundView, frame: CGRect(origin: CGPoint(), size: params.size))
            backgroundView.update(size: params.size, cornerRadius: params.cornerRadius ?? (params.size.height * 0.5), isDark: params.isDark, tintColor: GlassBackgroundView.TintColor(kind: .panel), isInteractive: true, transition: transition)
        }

        if contentView.bounds.size != params.size {
            contentView.clipsToBounds = true
            transition.setFrame(view: contentView, frame: CGRect(origin: CGPoint(), size: params.size), completion: { [weak self] completed in
                guard let self, completed else {
                    return
                }
                self.contentView.clipsToBounds = false
            })
            transition.setCornerRadius(layer: contentView.layer, cornerRadius: params.cornerRadius ?? (params.size.height * 0.5))

            liftedContainerView.clipsToBounds = true
            transition.setFrame(view: liftedContainerView, frame: CGRect(origin: CGPoint(), size: params.size), completion: { [weak self] completed in
                guard let self, completed else {
                    return
                }
                self.liftedContainerView.clipsToBounds = false
            })
            transition.setCornerRadius(layer: liftedContainerView.layer, cornerRadius: params.cornerRadius ?? (params.size.height * 0.5))
        }

        let baseLensFrame = CGRect(origin: params.selectionOrigin, size: params.selectionSize)
        updateLens(params: LensParams(baseFrame: baseLensFrame, inset: params.inset, liftedInset: params.liftedInset, isLifted: params.isLifted), transition: transition)

        if let legacyContentMaskView = legacyContentMaskView {
            transition.setFrame(view: legacyContentMaskView, frame: CGRect(origin: CGPoint(), size: params.size))
        }
        if let legacyContentMaskBlobView = legacyContentMaskBlobView, let legacyLiftedContentBlobMaskView = legacyLiftedContentBlobMaskView, let legacySelectionView = legacySelectionView {
            let lensFrame = baseLensFrame.insetBy(dx: params.inset, dy: params.inset)
            let effectiveLensFrame = lensFrame.insetBy(dx: params.isLifted ? -2.0 : 0.0, dy: params.isLifted ? -2.0 : 0.0)

            let diameter = min(lensFrame.width, lensFrame.height)
            if legacyContentMaskBlobView.image?.size.height != diameter {
                legacyContentMaskBlobView.image = generateStretchableFilledCircleImage(diameter: diameter, color: .black)
                legacyLiftedContentBlobMaskView.image = legacyContentMaskBlobView.image
                legacySelectionView.image = generateStretchableFilledCircleImage(diameter: diameter, color: .white)?.withRenderingMode(.alwaysTemplate)
            }
            transition.setFrame(view: legacyContentMaskBlobView, frame: effectiveLensFrame)
            transition.setFrame(view: legacyLiftedContentBlobMaskView, frame: effectiveLensFrame)

            legacySelectionView.tintColor = UIColor(white: params.isDark ? 1.0 : 0.0, alpha: params.isDark ? 0.1 : 0.075)
            transition.setFrame(view: legacySelectionView, frame: effectiveLensFrame)
        }

        // restingBackgroundView 需要比 liftedContainerView 更宽，防止 _UILiquidLensView
        // 内部 spring 回弹时 DestOutView 挖掉的区域超出 restingBackgroundView 的边界，
        // 导致露出下层 GlassBackgroundView 的白色背景。
        let overflowX = lensView != nil ? max(params.outerInsets.left, params.outerInsets.right) : 0
        let overflowY = lensView != nil ? max(params.outerInsets.top, params.outerInsets.bottom) : 0
        let restingFrame = CGRect(origin: .zero, size: params.size).insetBy(dx: -overflowX, dy: -overflowY)
        transition.setFrame(view: restingBackgroundView, frame: restingFrame)
        restingBackgroundView.update(isDark: params.isDark)
        transition.setAlpha(view: restingBackgroundView, alpha: (params.isLifted || params.isCollapsed) ? 0.0 : 1.0)

        if params.isLifted {
            if liftedDisplayLink == nil {
                liftedDisplayLink = SharedDisplayLinkDriver.shared.add(framesPerSecond: .max) { [weak self] _ in
                    guard let self else {
                        return
                    }
                    self.updateLiftedLensPosition()
                }
            }
        } else if let liftedDisplayLink = liftedDisplayLink {
            self.liftedDisplayLink = nil
            liftedDisplayLink.invalidate()
        }
    }
}
