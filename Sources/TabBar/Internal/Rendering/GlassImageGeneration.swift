//
//  GlassImageGeneration.swift
//  TabBar
//
//  Created by Sun on 2026/4/21.
//

import UIKit

// MARK: - Badge Path

extension CGContext {
    func addBadgePath(in rect: CGRect) {
        saveGState()
        translateBy(x: rect.minX, y: rect.minY)
        scaleBy(x: rect.width / 78.0, y: rect.height / 78.0)

        move(to: CGPoint(x: 0, y: 39))
        addCurve(to: CGPoint(x: 39, y: 0), control1: CGPoint(x: 0, y: 17.4609), control2: CGPoint(x: 17.4609, y: 0))
        addLine(to: CGPoint(x: 42, y: 0))
        addCurve(to: CGPoint(x: 78, y: 36), control1: CGPoint(x: 61.8823, y: 0), control2: CGPoint(x: 78, y: 16.1177))
        addLine(to: CGPoint(x: 78, y: 39))
        addCurve(to: CGPoint(x: 39, y: 78), control1: CGPoint(x: 78, y: 60.5391), control2: CGPoint(x: 60.5391, y: 78))
        addLine(to: CGPoint(x: 36, y: 78))
        addCurve(to: CGPoint(x: 0, y: 42), control1: CGPoint(x: 16.1177, y: 78), control2: CGPoint(x: 0, y: 61.8823))
        addLine(to: CGPoint(x: 0, y: 39))
        closePath()

        restoreGState()
    }
}

// MARK: - Legacy Glass Image

extension GlassBackgroundView {
    static func generateLegacyGlassImage(size: CGSize, inset: CGFloat, borderWidthFactor: CGFloat = 1.0, isDark: Bool, fillColor: UIColor) -> UIImage {
        var size = size
        if size == .zero {
            size = CGSize(width: 2.0, height: 2.0)
        }
        let innerSize = size
        size.width += inset * 2.0
        size.height += inset * 2.0

        return UIGraphicsImageRenderer(size: size).image { ctx in
            let context = ctx.cgContext
            context.clear(CGRect(origin: .zero, size: size))

            let addShadow: (CGContext, Bool, CGPoint, CGFloat, CGFloat, UIColor, CGBlendMode) -> Void = { context, isOuter, position, blur, spread, shadowColor, blendMode in
                var blur = blur

                if isOuter {
                    blur += abs(spread)
                    context.beginTransparencyLayer(auxiliaryInfo: nil)
                    context.saveGState()
                    defer {
                        context.restoreGState()
                        context.endTransparencyLayer()
                    }

                    let spreadRect = CGRect(origin: CGPoint(x: inset, y: inset), size: innerSize).insetBy(dx: 0.25, dy: 0.25)
                    let spreadPath = UIBezierPath(roundedRect: spreadRect, cornerRadius: min(spreadRect.width, spreadRect.height) * 0.5).cgPath

                    context.setShadow(offset: CGSize(width: position.x, height: position.y), blur: blur, color: shadowColor.cgColor)
                    context.setFillColor(UIColor.black.cgColor)
                    context.addPath(spreadPath)
                    context.fillPath()

                    let cleanRect = CGRect(origin: CGPoint(x: inset, y: inset), size: innerSize)
                    let cleanPath = UIBezierPath(roundedRect: cleanRect, cornerRadius: min(cleanRect.width, cleanRect.height) * 0.5).cgPath
                    context.setBlendMode(.copy)
                    context.setFillColor(UIColor.clear.cgColor)
                    context.addPath(cleanPath)
                    context.fillPath()
                    context.setBlendMode(.normal)
                } else {
                    let image = UIGraphicsImageRenderer(size: size).image(actions: { ctx in
                        let context = ctx.cgContext
                        context.clear(CGRect(origin: .zero, size: size))
                        let spreadRect = CGRect(origin: CGPoint(x: inset, y: inset), size: innerSize).insetBy(dx: -spread - 0.33, dy: -spread - 0.33)

                        context.setShadow(offset: CGSize(width: position.x, height: position.y), blur: blur, color: shadowColor.cgColor)
                        context.setFillColor(shadowColor.cgColor)
                        let enclosingRect = spreadRect.insetBy(dx: -10000.0, dy: -10000.0)
                        context.addPath(UIBezierPath(rect: enclosingRect).cgPath)
                        context.addBadgePath(in: spreadRect)
                        context.fillPath(using: .evenOdd)
                    })

                    UIGraphicsPushContext(context)
                    image.draw(in: CGRect(origin: .zero, size: size), blendMode: blendMode, alpha: 1.0)
                    UIGraphicsPopContext()
                }
            }

            addShadow(context, true, CGPoint(), 30.0, 0.0, UIColor(white: 0.0, alpha: 0.045), .normal)
            addShadow(context, true, CGPoint(), 20.0, 0.0, UIColor(white: 0.0, alpha: 0.01), .normal)

            var a: CGFloat = 0.0
            var b: CGFloat = 0.0
            var s: CGFloat = 0.0
            fillColor.getHue(nil, saturation: &s, brightness: &b, alpha: &a)

            let innerImage = UIGraphicsImageRenderer(size: size).image { ctx in
                let context = ctx.cgContext

                context.setFillColor(fillColor.cgColor)
                var ellipseRect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
                context.fillEllipse(in: ellipseRect)

                let lineWidth: CGFloat = 0.8 * borderWidthFactor
                let strokeColor: UIColor
                let blendMode: CGBlendMode
                let baseAlpha: CGFloat = isDark ? 0.3 : 0.6

                if s == 0.0 && abs(a - 0.7) < 0.1 && !isDark {
                    blendMode = .normal
                    strokeColor = UIColor(white: 1.0, alpha: baseAlpha)
                } else if s <= 0.3 && !isDark {
                    blendMode = .normal
                    strokeColor = UIColor(white: 1.0, alpha: 0.7 * baseAlpha)
                } else if b >= 0.2 {
                    let maxAlpha: CGFloat = isDark ? 0.7 : 0.8
                    blendMode = .overlay
                    strokeColor = UIColor(white: 1.0, alpha: max(0.5, min(1.0, maxAlpha * s)) * baseAlpha)
                } else {
                    blendMode = .normal
                    strokeColor = UIColor(white: 1.0, alpha: 0.5 * baseAlpha)
                }

                context.setStrokeColor(strokeColor.cgColor)
                ellipseRect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
                context.addEllipse(in: ellipseRect)
                context.clip()

                ellipseRect = ellipseRect.insetBy(dx: lineWidth * 0.5, dy: lineWidth * 0.5)
                context.setBlendMode(blendMode)

                let radius = ellipseRect.height * 0.5
                let smallerRadius = radius - lineWidth * 1.33
                context.move(to: CGPoint(x: ellipseRect.minX, y: ellipseRect.minY + radius))
                context.addArc(tangent1End: CGPoint(x: ellipseRect.minX, y: ellipseRect.minY), tangent2End: CGPoint(x: ellipseRect.minX + radius, y: ellipseRect.minY), radius: radius)
                context.addLine(to: CGPoint(x: ellipseRect.maxX - smallerRadius, y: ellipseRect.minY))
                context.addArc(tangent1End: CGPoint(x: ellipseRect.maxX, y: ellipseRect.minY), tangent2End: CGPoint(x: ellipseRect.maxX, y: ellipseRect.minY + smallerRadius), radius: smallerRadius)
                context.addLine(to: CGPoint(x: ellipseRect.maxX, y: ellipseRect.maxY - radius))
                context.addArc(tangent1End: CGPoint(x: ellipseRect.maxX, y: ellipseRect.maxY), tangent2End: CGPoint(x: ellipseRect.maxX - radius, y: ellipseRect.maxY), radius: radius)
                context.addLine(to: CGPoint(x: ellipseRect.minX + smallerRadius, y: ellipseRect.maxY))
                context.addArc(tangent1End: CGPoint(x: ellipseRect.minX, y: ellipseRect.maxY), tangent2End: CGPoint(x: ellipseRect.minX, y: ellipseRect.maxY - smallerRadius), radius: smallerRadius)
                context.closePath()
                context.strokePath()

                context.resetClip()
                context.setBlendMode(.normal)
            }
            innerImage.draw(in: CGRect(origin: .zero, size: size))
        }.stretchableImage(withLeftCapWidth: Int(size.width * 0.5), topCapHeight: Int(size.height * 0.5))
    }
}
