//
//  LiquidLensBridge.swift
//  TabBar
//
//  Created by Sun on 2026/4/22.
//

import Foundation
import UIKit

/// _UILiquidLensView 私有 API 桥接。
enum LiquidLensBridge {
    private enum Obfuscated {
        /// "_UILiquidLensView"
        static let className = "X1VJTGlxdWlkTGVuc1ZpZXc="
        /// "initWithRestingBackground:"
        static let initSelector = "aW5pdFdpdGhSZXN0aW5nQmFja2dyb3VuZDo="
        /// "setLiftedContainerView:"
        static let setLiftedContainer = "c2V0TGlmdGVkQ29udGFpbmVyVmlldzo="
        /// "setLiftedContentView:"
        static let setLiftedContent = "c2V0TGlmdGVkQ29udGVudFZpZXc6"
        /// "setOverridePunchoutView:"
        static let setOverridePunchout = "c2V0T3ZlcnJpZGVQdW5jaG91dFZpZXc6"
        /// "setLiftedContentMode:"
        static let setLiftedContentMode = "c2V0TGlmdGVkQ29udGVudE1vZGU6"
        /// "setStyle:"
        static let setStyle = "c2V0U3R5bGU6"
        /// "setWarpsContentBelow:"
        static let setWarpsContentBelow = "c2V0V2FycHNDb250ZW50QmVsb3c6"
        /// "setLifted:animated:alongsideAnimations:completion:"
        static let setLifted = "c2V0TGlmdGVkOmFuaW1hdGVkOmFsb25nc2lkZUFuaW1hdGlvbnM6Y29tcGxldGlvbjo="
        /// "restingBackgroundColor"
        static let restingBackgroundColor = "cmVzdGluZ0JhY2tncm91bmRDb2xvcg=="
    }

    private nonisolated(unsafe) static let lensClass: AnyObject? =
        NSClassFromString(decode(Obfuscated.className)) as AnyObject?

    /// 创建 _UILiquidLensView 实例。
    static func makeLensView(restingBackground: UIView) -> UIView? {
        guard let cls = lensClass as? NSObjectProtocol else { return nil }
        let allocSel = NSSelectorFromString("alloc")
        let initSel = Selector(decode(Obfuscated.initSelector))
        guard cls.responds(to: allocSel) else { return nil }
        let allocated = cls.perform(allocSel).takeUnretainedValue()
        guard allocated.responds(to: initSel) else { return nil }
        return allocated.perform(initSel, with: restingBackground)?.takeUnretainedValue() as? UIView
    }

    static func setLiftedContainerView(_ lens: UIView, view: UIView) {
        lens.perform(Selector(decode(Obfuscated.setLiftedContainer)), with: view)
    }

    static func setLiftedContentView(_ lens: UIView, view: UIView) {
        lens.perform(Selector(decode(Obfuscated.setLiftedContent)), with: view)
    }

    static func setOverridePunchoutView(_ lens: UIView, view: UIView) {
        lens.perform(Selector(decode(Obfuscated.setOverridePunchout)), with: view)
    }

    static func setLiftedContentMode(_ lens: UIView, mode: Int32) {
        let sel = Selector(decode(Obfuscated.setLiftedContentMode))
        guard let method = lens.method(for: sel) else { return }
        let fn = unsafeBitCast(method, to: (@convention(c) (AnyObject, Selector, Int32) -> Void).self)
        fn(lens, sel, mode)
    }

    static func setStyle(_ lens: UIView, style: Int32) {
        let sel = Selector(decode(Obfuscated.setStyle))
        guard let method = lens.method(for: sel) else { return }
        let fn = unsafeBitCast(method, to: (@convention(c) (AnyObject, Selector, Int32) -> Void).self)
        fn(lens, sel, style)
    }

    static func setWarpsContentBelow(_ lens: UIView, warps: Bool) {
        let sel = Selector(decode(Obfuscated.setWarpsContentBelow))
        guard let method = lens.method(for: sel) else { return }
        let fn = unsafeBitCast(method, to: (@convention(c) (AnyObject, Selector, Bool) -> Void).self)
        fn(lens, sel, warps)
    }

    static func setRestingBackgroundColor(_ lens: UIView, color: UIColor) {
        lens.setValue(color, forKey: decode(Obfuscated.restingBackgroundColor))
    }

    static func setLifted(
        _ lens: UIView,
        lifted: Bool,
        animated: Bool,
        alongside: @escaping () -> Void,
        completion: (() -> Void)?
    ) {
        let sel = Selector(decode(Obfuscated.setLifted))
        guard let method = lens.method(for: sel) else { return }
        let fn = unsafeBitCast(method, to: (@convention(c) (AnyObject, Selector, Bool, Bool, @escaping () -> Void, (() -> Void)?) -> Void).self)
        fn(lens, sel, lifted, animated, alongside, completion)
    }

    private static func decode(_ base64: String) -> String {
        guard let data = Data(base64Encoded: base64),
              let string = String(data: data, encoding: .utf8)
        else { return "" }
        return string
    }
}
