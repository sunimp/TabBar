//
//  ImageDrawing.swift
//  TabBar
//
//  Created by Sun on 2026/4/21.
//

import UIKit

private let drawingDeviceColorSpace: CGColorSpace = {
    if let colorSpace = CGColorSpace(name: CGColorSpace.displayP3) {
        return colorSpace
    } else {
        return CGColorSpaceCreateDeviceRGB()
    }
}()

private let drawingDeviceScale: CGFloat = UIScreenScale

private struct DeviceGraphicsContextSettings {
    static let shared = getSharedDeviceGraphicsContextSettings()

    let rowAlignment: Int
    let bitsPerPixel: Int
    let bitsPerComponent: Int
    let opaqueBitmapInfo: CGBitmapInfo
    let transparentBitmapInfo: CGBitmapInfo
    let colorSpace: CGColorSpace

    func bytesPerRow(forWidth width: Int) -> Int {
        let baseValue = bitsPerPixel * width / 8
        let alignmentMask = rowAlignment - 1
        return (baseValue + alignmentMask) & ~alignmentMask
    }
}

private func getSharedDeviceGraphicsContextSettings() -> DeviceGraphicsContextSettings {
    struct OpaqueSettings {
        let rowAlignment: Int
        let bitsPerPixel: Int
        let bitsPerComponent: Int
        let opaqueBitmapInfo: CGBitmapInfo
        let colorSpace: CGColorSpace

        init(context: CGContext) {
            rowAlignment = context.bytesPerRow
            bitsPerPixel = context.bitsPerPixel
            bitsPerComponent = context.bitsPerComponent
            opaqueBitmapInfo = context.bitmapInfo
            if let p3 = CGColorSpace(name: CGColorSpace.displayP3) {
                colorSpace = p3
            } else {
                colorSpace = context.colorSpace!
            }
        }
    }

    struct TransparentSettings {
        let transparentBitmapInfo: CGBitmapInfo

        init(context: CGContext) {
            transparentBitmapInfo = context.bitmapInfo
        }
    }

    var opaqueSettings: OpaqueSettings?
    var transparentSettings: TransparentSettings?

    let opaqueFormat = UIGraphicsImageRendererFormat()
    let transparentFormat = UIGraphicsImageRendererFormat()
    opaqueFormat.preferredRange = .standard
    transparentFormat.preferredRange = .standard
    opaqueFormat.opaque = true
    transparentFormat.opaque = false

    let opaqueRenderer = UIGraphicsImageRenderer(bounds: CGRect(origin: .zero, size: CGSize(width: 1.0, height: 1.0)), format: opaqueFormat)
    let _ = opaqueRenderer.image { context in
        opaqueSettings = OpaqueSettings(context: context.cgContext)
    }

    let transparentRenderer = UIGraphicsImageRenderer(bounds: CGRect(origin: .zero, size: CGSize(width: 1.0, height: 1.0)), format: transparentFormat)
    let _ = transparentRenderer.image { context in
        transparentSettings = TransparentSettings(context: context.cgContext)
    }

    return DeviceGraphicsContextSettings(
        rowAlignment: opaqueSettings!.rowAlignment,
        bitsPerPixel: opaqueSettings!.bitsPerPixel,
        bitsPerComponent: opaqueSettings!.bitsPerComponent,
        opaqueBitmapInfo: opaqueSettings!.opaqueBitmapInfo,
        transparentBitmapInfo: transparentSettings!.transparentBitmapInfo,
        colorSpace: opaqueSettings!.colorSpace
    )
}

final class DrawingContext {
    let size: CGSize
    let scale: CGFloat
    let scaledSize: CGSize
    let bytesPerRow: Int
    let length: Int

    private let imageBuffer: UnsafeMutableRawPointer
    private let context: CGContext
    private var hasGeneratedImage = false

    var bytes: UnsafeMutableRawPointer {
        if hasGeneratedImage {
            preconditionFailure()
        }
        return imageBuffer
    }

    init?(size: CGSize, scale: CGFloat = 0.0, opaque: Bool = false, clear: Bool = false, bytesPerRow: Int? = nil, colorSpace: CGColorSpace? = nil) {
        if size.width <= 0.0 || size.height <= 0.0 {
            return nil
        }

        let size = CGSize(width: max(1.0, size.width), height: max(1.0, size.height))
        let actualScale = scale.isZero ? drawingDeviceScale : scale
        self.size = size
        self.scale = actualScale
        scaledSize = CGSize(width: size.width * actualScale, height: size.height * actualScale)

        self.bytesPerRow = bytesPerRow ?? DeviceGraphicsContextSettings.shared.bytesPerRow(forWidth: Int(scaledSize.width))
        length = self.bytesPerRow * Int(scaledSize.height)
        imageBuffer = malloc(length)!

        let bitmapInfo: CGBitmapInfo = opaque ? DeviceGraphicsContextSettings.shared.opaqueBitmapInfo : DeviceGraphicsContextSettings.shared.transparentBitmapInfo

        guard let context = CGContext(
            data: imageBuffer,
            width: Int(scaledSize.width),
            height: Int(scaledSize.height),
            bitsPerComponent: DeviceGraphicsContextSettings.shared.bitsPerComponent,
            bytesPerRow: self.bytesPerRow,
            space: colorSpace ?? drawingDeviceColorSpace,
            bitmapInfo: bitmapInfo.rawValue,
            releaseCallback: nil,
            releaseInfo: nil
        ) else {
            free(imageBuffer)
            return nil
        }

        self.context = context
        self.context.scaleBy(x: self.scale, y: self.scale)

        if clear {
            memset(bytes, 0, length)
        }
    }

    deinit {
        if !hasGeneratedImage {
            free(imageBuffer)
        }
    }

    func withContext(_ body: (CGContext) -> Void) {
        context.translateBy(x: size.width / 2.0, y: size.height / 2.0)
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: -size.width / 2.0, y: -size.height / 2.0)

        body(context)

        context.translateBy(x: size.width / 2.0, y: size.height / 2.0)
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: -size.width / 2.0, y: -size.height / 2.0)
    }

    func withFlippedContext(_ body: (CGContext) -> Void) {
        body(context)
    }

    func generateImage(colorSpace: CGColorSpace? = nil) -> UIImage? {
        if scaledSize.width.isZero || scaledSize.height.isZero {
            return nil
        }
        if hasGeneratedImage {
            preconditionFailure()
        }
        hasGeneratedImage = true

        guard let dataProvider = CGDataProvider(dataInfo: imageBuffer, data: imageBuffer, size: length, releaseData: { info, _, _ in
            if let info = info {
                free(info)
            }
        }) else {
            return nil
        }

        guard let image = CGImage(
            width: Int(scaledSize.width),
            height: Int(scaledSize.height),
            bitsPerComponent: context.bitsPerComponent,
            bitsPerPixel: context.bitsPerPixel,
            bytesPerRow: context.bytesPerRow,
            space: colorSpace ?? drawingDeviceColorSpace,
            bitmapInfo: context.bitmapInfo,
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else {
            return nil
        }

        return UIImage(cgImage: image, scale: scale, orientation: .up)
    }
}

func generateImage(_ size: CGSize, contextGenerator: (CGSize, CGContext) -> Void, opaque: Bool = false, scale: CGFloat? = nil) -> UIImage? {
    if size.width.isZero || size.height.isZero {
        return nil
    }
    guard let context = DrawingContext(size: size, scale: scale ?? 0.0, opaque: opaque, clear: false) else {
        return nil
    }
    context.withFlippedContext { cgContext in
        contextGenerator(context.size, cgContext)
    }
    return context.generateImage()
}

func generateImage(_ size: CGSize, opaque: Bool = false, scale: CGFloat? = nil, rotatedContext: (CGSize, CGContext) -> Void) -> UIImage? {
    if size.width.isZero || size.height.isZero {
        return nil
    }
    guard let context = DrawingContext(size: size, scale: scale ?? 0.0, opaque: opaque, clear: false) else {
        return nil
    }
    context.withContext { cgContext in
        rotatedContext(context.size, cgContext)
    }
    return context.generateImage()
}

private func generateFilledCircleImage(diameter: CGFloat, color: UIColor?, strokeColor: UIColor? = nil, strokeWidth: CGFloat? = nil, backgroundColor: UIColor? = nil) -> UIImage? {
    generateImage(CGSize(width: diameter, height: diameter), contextGenerator: { size, context in
        context.clear(CGRect(origin: .zero, size: size))
        if let backgroundColor = backgroundColor {
            context.setFillColor(backgroundColor.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
        }

        if let strokeColor = strokeColor, let strokeWidth = strokeWidth {
            context.setFillColor(strokeColor.cgColor)
            context.fillEllipse(in: CGRect(origin: .zero, size: size))

            if let color = color {
                context.setFillColor(color.cgColor)
            } else {
                context.setFillColor(UIColor.clear.cgColor)
                context.setBlendMode(.copy)
            }
            context.fillEllipse(in: CGRect(origin: CGPoint(x: strokeWidth, y: strokeWidth), size: CGSize(width: size.width - strokeWidth * 2.0, height: size.height - strokeWidth * 2.0)))
        } else {
            if let color = color {
                context.setFillColor(color.cgColor)
            } else {
                context.setFillColor(UIColor.clear.cgColor)
                context.setBlendMode(.copy)
            }
            context.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
    })
}

func generateStretchableFilledCircleImage(diameter: CGFloat, color: UIColor?, strokeColor: UIColor? = nil, strokeWidth: CGFloat? = nil, backgroundColor: UIColor? = nil) -> UIImage? {
    let intRadius = Int(diameter / 2.0)
    let intDiameter = Int(diameter)
    let cap: Int
    if intDiameter == 3 {
        cap = 1
    } else if intDiameter == 2 {
        cap = 3
    } else if intRadius == 1 {
        cap = 2
    } else {
        cap = intRadius
    }

    return generateFilledCircleImage(diameter: diameter, color: color, strokeColor: strokeColor, strokeWidth: strokeWidth, backgroundColor: backgroundColor)?.stretchableImage(withLeftCapWidth: cap, topCapHeight: cap)
}
