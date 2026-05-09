//
//  SpringTimingBridge.swift
//  TabBar
//
//  Created by Sun on 2026/4/22.
//

import Foundation

/// 私有 Spring 动画 timing function 名称。
enum SpringTimingBridge {
    private enum Obfuscated {
        /// "CAAnimationUtilsSpringCurve"
        static let springCurve = "Q0FBbmltYXRpb25VdGlsc1NwcmluZ0N1cnZl"
        /// "CAAnimationUtilsSpringCustomCurve"
        static let springCustomCurvePrefix = "Q0FBbmltYXRpb25VdGlsc1NwcmluZ0N1c3RvbUN1cnZl"
    }

    /// "CAAnimationUtilsSpringCurve"
    static let springCurve: String = decode(Obfuscated.springCurve)
    /// "CAAnimationUtilsSpringCustomCurve"
    static let springCustomCurvePrefix: String = decode(Obfuscated.springCustomCurvePrefix)

    private static func decode(_ base64: String) -> String {
        guard let data = Data(base64Encoded: base64),
              let string = String(data: data, encoding: .utf8)
        else { return "" }
        return string
    }
}
