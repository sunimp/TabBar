//
//  TabBarStyle.swift
//  TabBar
//
//  Created by Sun on 2026/3/30.
//

import UIKit

/// TabBar 的主题样式配置。
///
/// 定义了 TabBar 各元素的颜色，包括图标、文字、角标和背景。
/// 预置了 `.default`（亮色）和 `.dark`（暗色）两套主题。
public struct TabBarStyle: Equatable {
    /// 控制器背景色（TabBar 后方的页面背景）。
    public var backgroundColor: UIColor
    /// 分隔线颜色（预留，当前未使用）。
    public var separatorColor: UIColor
    /// 未选中状态的图标颜色（仅 UIImage 模式，Lottie 模式使用 `textColor`）。
    public var iconColor: UIColor
    /// 选中状态的图标颜色（仅 UIImage 模式，Lottie 模式使用 `selectedTextColor`）。
    public var selectedIconColor: UIColor
    /// 未选中状态的标题和 Lottie 图标颜色。
    public var textColor: UIColor
    /// 选中状态的标题和 Lottie 图标颜色。
    public var selectedTextColor: UIColor
    /// 角标背景色。
    public var badgeBackgroundColor: UIColor
    /// 角标文字颜色。
    public var badgeTextColor: UIColor
    /// 角标描边颜色（预留，当前未使用）。
    public var badgeStrokeColor: UIColor
    /// 是否为暗色主题，影响毛玻璃背景和 Liquid Lens 的渲染参数。
    public var isDark: Bool

    public init(
        backgroundColor: UIColor, separatorColor: UIColor,
        iconColor: UIColor, selectedIconColor: UIColor,
        textColor: UIColor, selectedTextColor: UIColor,
        badgeBackgroundColor: UIColor, badgeTextColor: UIColor, badgeStrokeColor: UIColor,
        isDark: Bool
    ) {
        self.backgroundColor = backgroundColor
        self.separatorColor = separatorColor
        self.iconColor = iconColor
        self.selectedIconColor = selectedIconColor
        self.textColor = textColor
        self.selectedTextColor = selectedTextColor
        self.badgeBackgroundColor = badgeBackgroundColor
        self.badgeTextColor = badgeTextColor
        self.badgeStrokeColor = badgeStrokeColor
        self.isDark = isDark
    }

    /// 默认亮色主题。
    public static var `default`: TabBarStyle {
        TabBarStyle(
            backgroundColor: .systemBackground,
            separatorColor: .separator,
            iconColor: UIColor(red: 0.6, green: 0.6, blue: 0.65, alpha: 1.0),
            selectedIconColor: UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0),
            textColor: UIColor(red: 0.6, green: 0.6, blue: 0.65, alpha: 1.0),
            selectedTextColor: UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0),
            badgeBackgroundColor: UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0),
            badgeTextColor: .white,
            badgeStrokeColor: .white,
            isDark: false
        )
    }

    /// 暗色主题。
    public static var dark: TabBarStyle {
        TabBarStyle(
            backgroundColor: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0),
            separatorColor: UIColor(white: 1.0, alpha: 0.1),
            iconColor: UIColor(red: 0.55, green: 0.55, blue: 0.58, alpha: 1.0),
            selectedIconColor: UIColor(red: 0.35, green: 0.58, blue: 1.0, alpha: 1.0),
            textColor: UIColor(red: 0.55, green: 0.55, blue: 0.58, alpha: 1.0),
            selectedTextColor: UIColor(red: 0.35, green: 0.58, blue: 1.0, alpha: 1.0),
            badgeBackgroundColor: UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0),
            badgeTextColor: .white,
            badgeStrokeColor: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0),
            isDark: true
        )
    }
}
