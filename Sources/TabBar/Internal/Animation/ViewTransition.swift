//
//  ViewTransition.swift
//  TabBar
//
//  Created by Sun on 2026/3/30.
//

import UIKit

// MARK: - CALayer 动画桥接

extension CALayer {
    func animate(from: Any, to: Any, keyPath: String, duration: Double, delay: Double, curve: ViewTransition.Animation.Curve, removeOnCompletion: Bool, additive: Bool, completion: ((Bool) -> Void)? = nil, key: String? = nil) {
        if case let .bounce(stiffness, damping) = curve {
            animateSpring(
                from: from, to: to, keyPath: keyPath,
                duration: duration, delay: delay,
                stiffness: stiffness, damping: damping,
                removeOnCompletion: removeOnCompletion, additive: additive,
                completion: completion, key: key
            )
        } else {
            let timingFunction: String
            let mediaTimingFunction: CAMediaTimingFunction?
            switch curve {
            case .spring:
                timingFunction = kCAMediaTimingFunctionSpring
                mediaTimingFunction = nil
            default:
                timingFunction = CAMediaTimingFunctionName.easeInEaseOut.rawValue
                mediaTimingFunction = curve.asTimingFunction()
            }
            animate(
                from: from, to: to, keyPath: keyPath,
                timingFunction: timingFunction, duration: duration, delay: delay,
                mediaTimingFunction: mediaTimingFunction,
                removeOnCompletion: removeOnCompletion, additive: additive,
                completion: completion, key: key
            )
        }
    }
}

// MARK: - Curve 工具

private extension ViewTransition.Animation.Curve {
    func asTimingFunction() -> CAMediaTimingFunction {
        switch self {
        case .easeInOut:
            return CAMediaTimingFunction(name: .easeInEaseOut)
        case .linear:
            return CAMediaTimingFunction(name: .linear)
        case let .custom(a, b, c, d):
            return CAMediaTimingFunction(controlPoints: a, b, c, d)
        case .spring, .bounce:
            preconditionFailure()
        }
    }

    var viewAnimationOptions: UIView.AnimationOptions {
        switch self {
        case .linear: return [.curveLinear]
        case .easeInOut: return [.curveEaseInOut]
        case .spring: return UIView.AnimationOptions(rawValue: 7 << 16)
        case .custom, .bounce: return []
        }
    }
}

// MARK: - Animation

package extension ViewTransition.Animation {
    var isImmediate: Bool {
        if case .none = self { return true }
        return false
    }
}

// MARK: - ViewTransition

package struct ViewTransition {
    package enum Animation {
        package enum Curve {
            case easeInOut
            case spring
            case linear
            case custom(Float, Float, Float, Float)
            case bounce(stiffness: CGFloat, damping: CGFloat)
        }

        case none
        case curve(duration: Double, curve: Curve)
    }

    package var animation: Animation

    package func withAnimation(_ animation: Animation) -> ViewTransition {
        var result = self
        result.animation = animation
        return result
    }

    package static var immediate: ViewTransition = .init(animation: .none)

    package static func easeInOut(duration: Double) -> ViewTransition {
        ViewTransition(animation: .curve(duration: duration, curve: .easeInOut))
    }

    package static func spring(duration: Double) -> ViewTransition {
        ViewTransition(animation: .curve(duration: duration, curve: .spring))
    }

    package init(animation: Animation) {
        self.animation = animation
    }
}

// MARK: - animateView

package extension ViewTransition {
    func animateView(allowUserInteraction: Bool = true, delay: Double = 0.0, _ f: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        switch animation {
        case .none:
            f()
            completion?(true)
        case let .curve(duration, curve):
            var options = curve.viewAnimationOptions
            if allowUserInteraction { options.insert(.allowUserInteraction) }
            switch curve {
            case .spring, .bounce, .custom:
                var dampingValue: CGFloat = 500.0
                if case let .bounce(_, damping) = curve {
                    dampingValue = damping
                }
                UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: dampingValue, initialSpringVelocity: 0.0, options: options, animations: f, completion: completion)
            default:
                UIView.animate(withDuration: duration, delay: delay, options: options, animations: f, completion: completion)
            }
        }
    }
}

// MARK: - setFrame

package extension ViewTransition {
    func setFrame(view: UIView, frame: CGRect, completion: ((Bool) -> Void)? = nil) {
        if view.frame == frame {
            completion?(true)
            return
        }
        switch animation {
        case .none:
            view.frame = frame
            view.layer.removeAnimation(forKey: "position")
            view.layer.removeAnimation(forKey: "bounds")
            view.layer.removeAnimation(forKey: "bounds.size")
            completion?(true)
        case .curve:
            let previousPosition: CGPoint
            let previousBounds: CGRect
            if view.layer.animation(forKey: "position") != nil || view.layer.animation(forKey: "bounds") != nil || view.layer.animation(forKey: "bounds.size") != nil, let presentation = view.layer.presentation() {
                previousPosition = presentation.position
                previousBounds = presentation.bounds
            } else {
                previousPosition = view.layer.position
                previousBounds = view.layer.bounds
            }
            view.frame = frame
            let anchorPoint = view.layer.anchorPoint
            let updatedPosition = CGPoint(x: frame.minX + frame.width * anchorPoint.x, y: frame.minY + frame.height * anchorPoint.y)
            animatePosition(view: view, from: previousPosition, to: updatedPosition, completion: completion)
            if previousBounds.size != frame.size {
                animateBoundsSize(view: view, from: previousBounds.size, to: frame.size)
            }
        }
    }

    func setFrame(layer: CALayer, frame: CGRect, completion: ((Bool) -> Void)? = nil) {
        if layer.frame == frame {
            completion?(true)
            return
        }
        switch animation {
        case .none:
            layer.frame = frame
            layer.removeAnimation(forKey: "position")
            layer.removeAnimation(forKey: "bounds")
            completion?(true)
        case .curve:
            let previousFrame: CGRect
            if layer.animation(forKey: "position") != nil || layer.animation(forKey: "bounds") != nil, let presentation = layer.presentation() {
                previousFrame = presentation.frame
            } else {
                previousFrame = layer.frame
            }
            layer.frame = frame
            animatePosition(layer: layer, from: CGPoint(x: previousFrame.midX, y: previousFrame.midY), to: CGPoint(x: frame.midX, y: frame.midY), completion: completion)
            animateBounds(layer: layer, from: CGRect(origin: layer.bounds.origin, size: previousFrame.size), to: CGRect(origin: layer.bounds.origin, size: frame.size))
        }
    }
}

// MARK: - setBounds / setPosition

package extension ViewTransition {
    func setBounds(view: UIView, bounds: CGRect, completion: ((Bool) -> Void)? = nil) {
        if view.bounds == bounds {
            completion?(true)
            return
        }
        switch animation {
        case .none:
            view.bounds = bounds
            view.layer.removeAnimation(forKey: "bounds")
            view.layer.removeAnimation(forKey: "bounds.origin")
            view.layer.removeAnimation(forKey: "bounds.size")
            completion?(true)
        case .curve:
            let previousBounds: CGRect
            if view.layer.animation(forKey: "bounds") != nil || view.layer.animation(forKey: "bounds.origin") != nil || view.layer.animation(forKey: "bounds.size") != nil, let presentation = view.layer.presentation() {
                previousBounds = presentation.bounds
            } else {
                previousBounds = view.layer.bounds
            }
            view.bounds = bounds
            animateBounds(view: view, from: previousBounds, to: view.bounds, completion: completion)
        }
    }

    func setPosition(view: UIView, position: CGPoint, delay: Double = 0.0, completion: ((Bool) -> Void)? = nil) {
        if view.center == position {
            completion?(true)
            return
        }
        switch animation {
        case .none:
            view.center = position
            view.layer.removeAnimation(forKey: "position")
            completion?(true)
        case .curve:
            let previousPosition: CGPoint
            if view.layer.animation(forKey: "position") != nil, let presentation = view.layer.presentation() {
                previousPosition = presentation.position
            } else {
                previousPosition = view.layer.position
            }
            view.center = position
            animatePosition(view: view, from: previousPosition, to: view.center, delay: delay, completion: completion)
        }
    }
}

// MARK: - setAlpha / setScale / setCornerRadius

package extension ViewTransition {
    func setAlpha(view: UIView, alpha: CGFloat, delay: Double = 0.0, completion: ((Bool) -> Void)? = nil) {
        if view.alpha == alpha {
            completion?(true)
            return
        }
        switch animation {
        case .none:
            view.alpha = alpha
            view.layer.removeAnimation(forKey: "opacity")
            completion?(true)
        case let .curve(duration, curve):
            let previousAlpha: Float
            if view.layer.animation(forKey: "opacity") != nil {
                previousAlpha = view.layer.presentation()?.opacity ?? Float(view.alpha)
            } else {
                previousAlpha = Float(view.alpha)
            }
            view.alpha = alpha
            view.layer.animate(
                from: CGFloat(previousAlpha) as NSNumber, to: alpha as NSNumber,
                keyPath: "opacity", duration: duration, delay: delay, curve: curve,
                removeOnCompletion: true, additive: false, completion: completion
            )
        }
    }

    func setScale(view: UIView, scale: CGFloat, delay: Double = 0.0, completion: ((Bool) -> Void)? = nil) {
        setScale(layer: view.layer, scale: scale, delay: delay, completion: completion)
    }

    func setScale(layer: CALayer, scale: CGFloat, delay: Double = 0.0, beginWithCurrentState: Bool = false, completion: ((Bool) -> Void)? = nil) {
        let currentTransform: CATransform3D
        if beginWithCurrentState, layer.animation(forKey: "transform") != nil || layer.animation(forKey: "transform.scale") != nil {
            currentTransform = layer.presentation()?.transform ?? layer.transform
        } else {
            currentTransform = layer.transform
        }
        let currentScale = sqrt((currentTransform.m11 * currentTransform.m11) + (currentTransform.m12 * currentTransform.m12) + (currentTransform.m13 * currentTransform.m13))
        if currentScale == scale {
            if let animation = layer.animation(forKey: "transform.scale") as? CABasicAnimation, let toValue = animation.toValue as? NSNumber {
                if toValue.doubleValue == scale {
                    completion?(true)
                    return
                }
            } else {
                completion?(true)
                return
            }
        }
        switch animation {
        case .none:
            layer.transform = CATransform3DMakeScale(scale, scale, 1.0)
            completion?(true)
        case let .curve(duration, curve):
            layer.transform = CATransform3DMakeScale(scale, scale, 1.0)
            layer.animate(
                from: currentScale as NSNumber, to: scale as NSNumber,
                keyPath: "transform.scale", duration: duration, delay: delay, curve: curve,
                removeOnCompletion: true, additive: false, completion: completion
            )
        }
    }

    func setCornerRadius(layer: CALayer, cornerRadius: CGFloat, completion: ((Bool) -> Void)? = nil) {
        if layer.cornerRadius == cornerRadius {
            completion?(true)
            return
        }
        switch animation {
        case .none:
            layer.cornerRadius = cornerRadius
            completion?(true)
        case let .curve(duration, curve):
            let fromValue: CGFloat
            if layer.animation(forKey: "cornerRadius") != nil, let presentation = layer.presentation() {
                fromValue = presentation.cornerRadius
            } else {
                fromValue = layer.cornerRadius
            }
            layer.cornerRadius = cornerRadius
            layer.animate(
                from: fromValue as NSNumber, to: cornerRadius as NSNumber,
                keyPath: "cornerRadius", duration: duration, delay: 0.0, curve: curve,
                removeOnCompletion: true, additive: false, completion: completion
            )
        }
    }
}

// MARK: - animate 辅助方法

package extension ViewTransition {
    func animateScale(view: UIView, from fromValue: CGFloat, to toValue: CGFloat, delay: Double = 0.0, additive: Bool = false, completion: ((Bool) -> Void)? = nil) {
        switch animation {
        case .none:
            completion?(true)
        case let .curve(duration, curve):
            view.layer.animate(
                from: fromValue as NSNumber, to: toValue as NSNumber,
                keyPath: "transform.scale", duration: duration, delay: delay, curve: curve,
                removeOnCompletion: true, additive: additive, completion: completion
            )
        }
    }

    func animateAlpha(view: UIView, from fromValue: CGFloat, to toValue: CGFloat, delay: Double = 0.0, additive: Bool = false, completion: ((Bool) -> Void)? = nil) {
        switch animation {
        case .none:
            completion?(true)
        case let .curve(duration, curve):
            view.layer.animate(
                from: fromValue as NSNumber, to: toValue as NSNumber,
                keyPath: "opacity", duration: duration, delay: delay, curve: curve,
                removeOnCompletion: true, additive: additive, completion: completion
            )
        }
    }

    func animatePosition(layer: CALayer, from fromValue: CGPoint, to toValue: CGPoint, delay: Double = 0.0, additive: Bool = false, completion: ((Bool) -> Void)? = nil) {
        switch animation {
        case .none:
            completion?(true)
        case let .curve(duration, curve):
            layer.animate(
                from: NSValue(cgPoint: fromValue), to: NSValue(cgPoint: toValue),
                keyPath: "position", duration: duration, delay: delay, curve: curve,
                removeOnCompletion: true, additive: additive, completion: completion
            )
        }
    }
}

// MARK: - 内部动画辅助

private extension ViewTransition {
    func animatePosition(view: UIView, from fromValue: CGPoint, to toValue: CGPoint, delay: Double = 0.0, completion: ((Bool) -> Void)? = nil) {
        animatePosition(layer: view.layer, from: fromValue, to: toValue, delay: delay, completion: completion)
    }

    func animateBoundsSize(view: UIView, from fromValue: CGSize, to toValue: CGSize, completion: ((Bool) -> Void)? = nil) {
        animateBoundsSize(layer: view.layer, from: fromValue, to: toValue, completion: completion)
    }

    func animateBoundsSize(layer: CALayer, from fromValue: CGSize, to toValue: CGSize, completion: ((Bool) -> Void)? = nil) {
        switch animation {
        case .none:
            completion?(true)
        case let .curve(duration, curve):
            layer.animate(
                from: NSValue(cgSize: fromValue), to: NSValue(cgSize: toValue),
                keyPath: "bounds.size", duration: duration, delay: 0.0, curve: curve,
                removeOnCompletion: true, additive: false, completion: completion
            )
        }
    }

    func animateBounds(view: UIView, from fromValue: CGRect, to toValue: CGRect, completion: ((Bool) -> Void)? = nil) {
        animateBounds(layer: view.layer, from: fromValue, to: toValue, completion: completion)
    }

    func animateBounds(layer: CALayer, from fromValue: CGRect, to toValue: CGRect, completion: ((Bool) -> Void)? = nil) {
        switch animation {
        case .none:
            completion?(true)
        case let .curve(duration, curve):
            layer.animate(
                from: NSValue(cgRect: fromValue), to: NSValue(cgRect: toValue),
                keyPath: "bounds", duration: duration, delay: 0.0, curve: curve,
                removeOnCompletion: true, additive: false, completion: completion
            )
        }
    }
}
