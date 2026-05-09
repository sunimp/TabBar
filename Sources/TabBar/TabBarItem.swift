//
//  TabBarItem.swift
//  TabBar
//
//  Created by Sun on 2026/4/20.
//

import UIKit

// MARK: - TabBarItemAnimation

/// TabBar 项的 Lottie 动画配置。
public struct TabBarItemAnimation: Equatable {
    /// 动画播放模式。
    public enum PlaybackMode: Equatable {
        /// 播放一次后停留在最后一帧。
        case playOnce
        /// 循环播放。
        case loop
    }

    /// Lottie 动画资源名称（在 Bundle.main 或 SPM 资源中查找）。
    public var name: String
    /// 动画视图相对于默认位置的偏移量，用于微调对齐。
    public var offset: CGPoint
    /// 播放模式，默认为 `.playOnce`。
    public var playbackMode: PlaybackMode

    public init(name: String, offset: CGPoint = .zero, playbackMode: PlaybackMode = .playOnce) {
        self.name = name
        self.offset = offset
        self.playbackMode = playbackMode
    }
}

// MARK: - TabBarItem

/// TabBar 中单个 tab 的数据模型。
///
/// 每个 `TabBarItem` 描述一个 tab 的标题、图标、角标和动画配置。
/// 与 `TabBarController` 中的子控制器通过数组索引一一对应。
public struct TabBarItem: Equatable {
    /// 用于内部视图复用的稳定标识符。
    ///
    /// 默认使用 UUID 自动生成。如果需要跨 `setItems` 调用保持视图复用
    /// （例如仅更新 `badgeValue` 而不重建视图），请传入稳定的 id。
    public var id: String

    /// tab 标题，显示在图标下方。为空字符串时不显示标题。
    public var title: String
    /// 未选中状态的图标。当 `animation` 不为 nil 时此属性被忽略。
    public var image: UIImage?
    /// 选中状态的图标。当 `animation` 不为 nil 时此属性被忽略。
    public var selectedImage: UIImage?
    /// 角标文本（如未读消息数）。为 nil 或空字符串时不显示角标。
    public var badgeValue: String?
    /// Lottie 动画配置。设置后会替代 `image` / `selectedImage` 显示动画图标。
    public var animation: TabBarItemAnimation?
    /// 无障碍标识符，用于 UI 测试。
    public var accessibilityIdentifier: String?

    public init(
        id: String = UUID().uuidString,
        title: String,
        image: UIImage? = nil,
        selectedImage: UIImage? = nil,
        badgeValue: String? = nil,
        animation: TabBarItemAnimation? = nil,
        accessibilityIdentifier: String? = nil
    ) {
        self.id = id
        self.title = title
        self.image = image
        self.selectedImage = selectedImage
        self.badgeValue = badgeValue
        self.animation = animation
        self.accessibilityIdentifier = accessibilityIdentifier
    }
}
