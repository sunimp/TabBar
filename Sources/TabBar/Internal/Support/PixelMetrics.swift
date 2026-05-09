//
//  PixelMetrics.swift
//  TabBar
//
//  Created by Sun on 2026/4/21.
//

import UIKit

/// 屏幕像素密度（points per pixel）。
///
/// iOS 17+ 使用 `UITraitCollection.current.displayScale`，
/// 低版本使用 `UIScreen.main.scale`。
/// 值为 0 时兜底为 3.0（3x 屏幕）。
let UIScreenScale: CGFloat = {
    if #available(iOS 17.0, *) {
        return UITraitCollection.current.displayScale.isZero ? 3.0 : UITraitCollection.current.displayScale
    } else {
        return UIScreen.main.scale
    }
}()

/// 单个屏幕像素的 point 值（1.0 / scale）。
let UIScreenPixel = 1.0 / UIScreenScale

/// 将 point 值向下取整到最近的屏幕像素边界，避免亚像素渲染导致的模糊。
func floorToScreenPixels(_ value: CGFloat) -> CGFloat {
    floor(value * UIScreenScale) / UIScreenScale
}
