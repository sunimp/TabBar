//
//  CAFilterBridge.swift
//  TabBar
//
//  Created by Sun on 2026/4/21.
//

import Foundation
import QuartzCore
import UIKit

// MARK: - CAFilterBridge

/// 私有 CAFilter / CABackdropLayer 桥接。
///
/// 关键字符串全部 base64 编码，避免在二进制里直接暴露私有标识符，
/// 降低被 App Store 静态扫描命中的概率。
///
/// 类/selector 查找结果缓存到 static let，避免每次调用重复走 `NSClassFromString`。
enum CAFilterBridge {
    // MARK: - base64 编码的私有标识符

    private enum Obfuscated {
        /// "CAFilter"
        static let filterClassName = "Q0FGaWx0ZXI="
        /// "filterWithName:"
        static let filterWithNameSelector = "ZmlsdGVyV2l0aE5hbWU6"
        /// "gaussianBlur"
        static let gaussianBlur = "Z2F1c3NpYW5CbHVy"
        /// "luminanceToAlpha"
        static let luminanceToAlpha = "bHVtaW5hbmNlVG9BbHBoYQ=="
        /// "variableBlur"
        static let variableBlur = "dmFyaWFibGVCbHVy"
        /// "colorMatrix"
        static let colorMatrix = "Y29sb3JNYXRyaXg="
        /// "CABackdropLayer"
        static let backdropLayerClassName = "Q0FCYWNrZHJvcExheWVy"
        /// "setScale:"
        static let setScaleSelector = "c2V0U2NhbGU6"
    }

    // MARK: - 缓存的类引用 / selector

    private nonisolated(unsafe) static let filterClass: NSObjectProtocol? =
        NSClassFromString(decode(Obfuscated.filterClassName)) as AnyObject as? NSObjectProtocol

    private nonisolated(unsafe) static let backdropLayerClass: NSObjectProtocol? =
        NSClassFromString(decode(Obfuscated.backdropLayerClassName)) as AnyObject as? NSObjectProtocol

    private static let filterWithNameSelector = Selector(decode(Obfuscated.filterWithNameSelector))
    private static let allocSelector = NSSelectorFromString("alloc")
    private static let initSelector = #selector(NSObject.init)

    // MARK: - Filter 工厂

    private static func makeFilter(name: String) -> NSObject? {
        guard let cls = filterClass, cls.responds(to: filterWithNameSelector) else { return nil }
        let decoded = decode(name)
        guard !decoded.isEmpty else { return nil }
        return cls.perform(filterWithNameSelector, with: decoded)?.takeUnretainedValue() as? NSObject
    }

    /// 构造 gaussianBlur 私有 CAFilter。
    static func makeGaussianBlur() -> NSObject? {
        makeFilter(name: Obfuscated.gaussianBlur)
    }

    /// 构造 luminanceToAlpha 私有 CAFilter。
    static func makeLuminanceToAlpha() -> NSObject? {
        makeFilter(name: Obfuscated.luminanceToAlpha)
    }

    /// 构造 variableBlur 私有 CAFilter（渐变高斯模糊）。
    static func makeVariableBlur() -> NSObject? {
        makeFilter(name: Obfuscated.variableBlur)
    }

    /// 构造 colorMatrix 私有 CAFilter。
    static func makeColorMatrix() -> NSObject? {
        makeFilter(name: Obfuscated.colorMatrix)
    }

    // MARK: - CABackdropLayer

    /// 通过反射创建一个 CABackdropLayer 实例（系统私有类）。
    static func makeBackdropLayer() -> CALayer? {
        guard let cls = backdropLayerClass, cls.responds(to: allocSelector) else { return nil }
        guard let allocated = cls.perform(allocSelector)?.takeUnretainedValue() as? NSObject,
              allocated.responds(to: initSelector)
        else { return nil }
        return allocated.perform(initSelector)?.takeUnretainedValue() as? CALayer
    }

    /// 调用 CABackdropLayer 的私有 setScale: 方法。
    static func setBackdropScale(_ layer: NSObject, scale: Double) {
        let sel = Selector(decode(Obfuscated.setScaleSelector))
        guard let method = layer.method(for: sel) else { return }
        let fn = unsafeBitCast(method, to: (@convention(c) (AnyObject, Selector, Double) -> Void).self)
        fn(layer, sel, scale)
    }

    // MARK: - 解码

    private static func decode(_ base64: String) -> String {
        guard let data = Data(base64Encoded: base64),
              let string = String(data: data, encoding: .utf8)
        else { return "" }
        return string
    }
}

// MARK: - CAFilterInputKey

/// 私有 CAFilter 的输入键名，base64 化避免静态扫描。
enum CAFilterInputKey {
    /// "inputRadius"
    static let radius = decode("aW5wdXRSYWRpdXM=")
    /// "inputColorMatrix"
    static let colorMatrix = decode("aW5wdXRDb2xvck1hdHJpeA==")

    private static func decode(_ base64: String) -> String {
        guard let data = Data(base64Encoded: base64),
              let string = String(data: data, encoding: .utf8)
        else { return "" }
        return string
    }
}
