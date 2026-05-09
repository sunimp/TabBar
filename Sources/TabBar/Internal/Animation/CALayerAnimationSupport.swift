//
//  CALayerAnimationSupport.swift
//  TabBar
//
//  Created by Sun on 2026/4/21.
//

import UIKit

extension CALayer {
    func makeAnimation(
        from: Any?,
        to: Any,
        keyPath: String,
        timingFunction: String,
        duration: Double,
        delay: Double = 0.0,
        mediaTimingFunction: CAMediaTimingFunction? = nil,
        removeOnCompletion: Bool = true,
        additive: Bool = false,
        completion: ((Bool) -> Void)? = nil
    ) -> CAAnimation {
        if timingFunction.hasPrefix(kCAMediaTimingFunctionCustomSpringPrefix) {
            let components = timingFunction.components(separatedBy: "_")
            let damping = Float(components[1]) ?? 100.0
            let initialVelocity = Float(components[2]) ?? 0.0

            let animation = CASpringAnimation(keyPath: keyPath)
            animation.fromValue = from
            animation.toValue = to
            animation.isRemovedOnCompletion = removeOnCompletion
            animation.fillMode = CAMediaTimingFillMode.forwards
            animation.completion = completion
            animation.damping = CGFloat(damping)
            animation.initialVelocity = CGFloat(initialVelocity)
            animation.mass = 5.0
            animation.stiffness = 900.0
            animation.duration = animation.settlingDuration
            animation.timingFunction = CAMediaTimingFunction(name: .linear)
            let k = Float(UIView.animationDurationFactor)
            var speed: Float = 1.0
            if k != 0, k != 1 {
                speed = 1.0 / k
            }
            animation.speed = speed * Float(animation.duration / duration)
            animation.isAdditive = additive
            if !delay.isZero {
                animation.beginTime = convertTime(CACurrentMediaTime(), from: nil) + delay * UIView.animationDurationFactor
                animation.fillMode = CAMediaTimingFillMode.both
            }
            adjustFrameRate(animation: animation)
            return animation
        } else if timingFunction == kCAMediaTimingFunctionSpring {
            if duration == 0.5 {
                let animation = makeSpringAnimation(keyPath, duration: duration)
                animation.fromValue = from
                animation.toValue = to
                animation.isRemovedOnCompletion = removeOnCompletion
                animation.fillMode = CAMediaTimingFillMode.forwards
                animation.completion = completion

                let k = Float(UIView.animationDurationFactor)
                var speed: Float = 1.0
                if k != 0, k != 1 {
                    speed = 1.0 / k
                }

                animation.speed = speed * Float(animation.duration / duration)
                animation.isAdditive = additive

                if !delay.isZero {
                    animation.beginTime = convertTime(CACurrentMediaTime(), from: nil) + delay * UIView.animationDurationFactor
                    animation.fillMode = CAMediaTimingFillMode.both
                }

                adjustFrameRate(animation: animation)
                return animation
            } else {
                let k = Float(UIView.animationDurationFactor)
                var speed: Float = 1.0
                if k != 0, k != 1 {
                    speed = 1.0 / k
                }

                let animation = CABasicAnimation(keyPath: keyPath)
                animation.fromValue = from
                animation.toValue = to
                animation.duration = duration
                animation.timingFunction = CAMediaTimingFunction(controlPoints: 0.380, 0.700, 0.125, 1.000)
                animation.isRemovedOnCompletion = removeOnCompletion
                animation.fillMode = CAMediaTimingFillMode.forwards
                animation.speed = speed
                animation.isAdditive = additive
                animation.completion = completion

                if !delay.isZero {
                    animation.beginTime = convertTime(CACurrentMediaTime(), from: nil) + delay * UIView.animationDurationFactor
                    animation.fillMode = CAMediaTimingFillMode.both
                }

                adjustFrameRate(animation: animation)
                return animation
            }
        } else {
            let k = Float(UIView.animationDurationFactor)
            var speed: Float = 1.0
            if k != 0, k != 1 {
                speed = 1.0 / k
            }

            let animation = CABasicAnimation(keyPath: keyPath)
            animation.fromValue = from
            animation.toValue = to
            animation.duration = duration
            if let mediaTimingFunction = mediaTimingFunction {
                animation.timingFunction = mediaTimingFunction
            } else {
                switch timingFunction {
                case CAMediaTimingFunctionName.linear.rawValue,
                     CAMediaTimingFunctionName.easeIn.rawValue,
                     CAMediaTimingFunctionName.easeOut.rawValue,
                     CAMediaTimingFunctionName.easeInEaseOut.rawValue,
                     CAMediaTimingFunctionName.default.rawValue:
                    animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName(rawValue: timingFunction))
                default:
                    animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                }
            }
            animation.isRemovedOnCompletion = removeOnCompletion
            animation.fillMode = CAMediaTimingFillMode.forwards
            animation.speed = speed
            animation.isAdditive = additive
            animation.completion = completion

            if !delay.isZero {
                animation.beginTime = convertTime(CACurrentMediaTime(), from: nil) + delay * UIView.animationDurationFactor
                animation.fillMode = CAMediaTimingFillMode.both
            }

            adjustFrameRate(animation: animation)
            return animation
        }
    }

    func animate(
        from: Any?,
        to: Any,
        keyPath: String,
        timingFunction: String,
        duration: Double,
        delay: Double = 0.0,
        mediaTimingFunction: CAMediaTimingFunction? = nil,
        removeOnCompletion: Bool = true,
        additive: Bool = false,
        completion: ((Bool) -> Void)? = nil,
        key: String? = nil
    ) {
        let animation = makeAnimation(
            from: from,
            to: to,
            keyPath: keyPath,
            timingFunction: timingFunction,
            duration: duration,
            delay: delay,
            mediaTimingFunction: mediaTimingFunction,
            removeOnCompletion: removeOnCompletion,
            additive: additive,
            completion: completion
        )
        add(animation, forKey: key ?? (additive ? nil : keyPath))
    }

    func animateSpring(
        from: Any,
        to: Any,
        keyPath: String,
        duration: Double,
        delay: Double = 0.0,
        initialVelocity: CGFloat = 0.0,
        stiffness: CGFloat = 900.0,
        damping: CGFloat = 88.0,
        removeOnCompletion: Bool = true,
        additive: Bool = false,
        completion: ((Bool) -> Void)? = nil,
        key: String? = nil
    ) {
        let animation = makeSpringBounceAnimation(keyPath, initialVelocity, damping)
        animation.stiffness = stiffness
        animation.fromValue = from
        animation.toValue = to
        animation.isRemovedOnCompletion = removeOnCompletion
        animation.fillMode = .forwards
        animation.completion = completion

        let k = Float(UIView.animationDurationFactor)
        var speed: Float = 1.0
        if k != 0, k != 1 {
            speed = 1.0 / k
        }

        if !delay.isZero {
            animation.beginTime = convertTime(CACurrentMediaTime(), from: nil) + delay * UIView.animationDurationFactor
            animation.fillMode = .both
        }

        animation.speed = speed * Float(animation.duration / duration)
        animation.isAdditive = additive

        adjustFrameRate(animation: animation)
        add(animation, forKey: additive ? key : (key ?? keyPath))
    }
}
