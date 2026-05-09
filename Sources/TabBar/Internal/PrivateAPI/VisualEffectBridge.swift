//
//  VisualEffectBridge.swift
//  TabBar
//
//  Created by Sun on 2026/4/22.
//

import Foundation
import UIKit

// MARK: - EffectSettingsBridge

/// UIView 的私有亮度范围 API 桥接。
enum EffectSettingsBridge {
    private enum Obfuscated {
        /// "_setBackgroundLuminanceMin:"
        static let setLumaMin = "X3NldEJhY2tncm91bmRMdW1pbmFuY2VNaW46"
        /// "_setBackgroundLuminanceMax:"
        static let setLumaMax = "X3NldEJhY2tncm91bmRMdW1pbmFuY2VNYXg6"
    }

    static func setLuminanceRange(view: UIView, min: CGFloat, max: CGFloat) {
        let minSel = Selector(decode(Obfuscated.setLumaMin))
        let maxSel = Selector(decode(Obfuscated.setLumaMax))
        if view.responds(to: minSel) {
            view.perform(minSel, with: NSNumber(value: Double(min)))
        }
        if view.responds(to: maxSel) {
            view.perform(maxSel, with: NSNumber(value: Double(max)))
        }
    }

    private static func decode(_ base64: String) -> String {
        guard let data = Data(base64Encoded: base64),
              let string = String(data: data, encoding: .utf8)
        else { return "" }
        return string
    }
}

// MARK: - MonochromaticBridge

/// UIView 的私有单色效果 API 桥接。
enum MonochromaticBridge {
    private enum Obfuscated {
        /// "_setAllowsMonochromaticTreatment:"
        static let setAllows = "X3NldEFsbG93c01vbm9jaHJvbWF0aWNUcmVhdG1lbnQ6"
        /// "_setEnableMonochromaticTreatment:"
        static let setEnable = "X3NldEVuYWJsZU1vbm9jaHJvbWF0aWNUcmVhdG1lbnQ6"
        /// "_setMonochromaticTreatment:"
        static let setTreatment = "X3NldE1vbm9jaHJvbWF0aWNUcmVhdG1lbnQ6"
    }

    static func setEnabled(_ view: UIView, enabled: Bool) {
        guard #available(iOS 26.0, *) else { return }
        for base64 in [Obfuscated.setAllows, Obfuscated.setEnable] {
            let sel = Selector(decode(base64))
            if view.responds(to: sel) {
                view.perform(sel, with: NSNumber(value: enabled))
            }
        }
        let treatmentSel = Selector(decode(Obfuscated.setTreatment))
        if view.responds(to: treatmentSel) {
            view.perform(treatmentSel, with: NSNumber(value: enabled ? 2 : 0))
        }
    }

    private static func decode(_ base64: String) -> String {
        guard let data = Data(base64Encoded: base64),
              let string = String(data: data, encoding: .utf8)
        else { return "" }
        return string
    }
}

// MARK: - VisualEffectBridge

/// UIVisualEffectView 内部子视图识别。
enum VisualEffectBridge {
    private enum Obfuscated {
        /// "VisualEffectSubview"
        static let subviewIdentifier = "VmlzdWFsRWZmZWN0U3Vidmlldw=="
    }

    /// 检查视图描述是否包含 VisualEffectSubview 标识。
    static func isEffectSubview(_ view: UIView) -> Bool {
        view.description.contains(decode(Obfuscated.subviewIdentifier))
    }

    private static func decode(_ base64: String) -> String {
        guard let data = Data(base64Encoded: base64),
              let string = String(data: data, encoding: .utf8)
        else { return "" }
        return string
    }
}
