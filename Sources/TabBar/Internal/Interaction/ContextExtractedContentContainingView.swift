//
//  ContextExtractedContentContainingView.swift
//  TabBar
//
//  Created by Sun on 2026/3/30.
//

import UIKit

/// 上下文菜单内容的容器视图。
///
/// 用于长按 tab 时提取内容进行预览。内部持有一个 `contentView` 子视图，
/// 自动跟随父视图尺寸。
final class ContextExtractedContentContainingView: UIView {
    /// 实际内容容器，tab 的图标、标题等子视图添加到此处。
    let contentView: UIView = .init()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(contentView)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
    }
}
