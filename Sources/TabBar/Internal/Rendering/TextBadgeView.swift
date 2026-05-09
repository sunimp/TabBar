//
//  TextBadgeView.swift
//  TabBar
//
//  Created by Sun on 2026/4/21.
//

import UIKit

/// 文字角标视图，用于显示未读消息数等信息。
///
/// 使用圆角胶囊形背景 + 居中文字渲染。文字通过 `DrawingContext` 预渲染为图片，
/// 以 `alwaysTemplate` 模式显示，支持通过 tintColor 动态着色。
/// 背景使用可拉伸的圆形图片，自动适应不同宽度。
final class TextBadgeView: UIView {
    /// 圆角胶囊背景。
    private let backgroundView: UIImageView
    /// 预渲染的文字图片视图。
    private let textContentsView: UIImageView

    /// 文字布局缓存。
    private struct TextLayout {
        var size: CGSize
        var opticalBounds: CGRect
    }

    private var textLayout: TextLayout?
    /// 当前文字内容，用于避免重复渲染。
    private var currentText: String?
    /// 当前字体，用于避免重复渲染。
    private var currentFont: UIFont?

    override init(frame: CGRect) {
        backgroundView = UIImageView()
        textContentsView = UIImageView()
        textContentsView.layer.anchorPoint = CGPoint()

        super.init(frame: frame)

        addSubview(backgroundView)
        addSubview(textContentsView)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 更新角标内容和样式，返回计算后的尺寸。
    ///
    /// 文字或字体变化时重新渲染文字图片；尺寸变化时重新生成背景图片。
    /// 宽度至少等于高度，确保单字符时显示为圆形。
    func update(text: String, font: UIFont, background: UIColor, foreground: UIColor, insets: UIEdgeInsets, availableSize: CGSize, transition: ViewTransition) -> CGSize {
        if text != currentText || font != currentFont {
            currentText = text
            currentFont = font

            let attributedText = NSAttributedString(string: text, attributes: [
                .font: font,
                .foregroundColor: UIColor.white,
            ])

            var boundingRect = attributedText.boundingRect(with: availableSize, options: .usesLineFragmentOrigin, context: nil)
            boundingRect.size.width = ceil(boundingRect.size.width)
            boundingRect.size.height = ceil(boundingRect.size.height)

            if let context = DrawingContext(size: boundingRect.size, scale: 0.0, opaque: false, clear: true) {
                context.withContext { c in
                    UIGraphicsPushContext(c)
                    defer { UIGraphicsPopContext() }
                    attributedText.draw(at: CGPoint())
                }
                textContentsView.image = context.generateImage()?.withRenderingMode(.alwaysTemplate)
                textLayout = TextLayout(size: boundingRect.size, opticalBounds: .zero)
            } else {
                textLayout = TextLayout(size: boundingRect.size, opticalBounds: CGRect(origin: .zero, size: boundingRect.size))
            }
        }

        let textSize = textLayout?.size ?? CGSize(width: 1.0, height: 1.0)

        var size = CGSize(width: textSize.width + insets.left + insets.right, height: textSize.height + insets.top + insets.bottom)
        size.width = max(size.width, size.height)

        transition.setFrame(view: backgroundView, frame: CGRect(origin: .zero, size: size))

        let textFrame = CGRect(origin: CGPoint(x: floorToScreenPixels((size.width - textSize.width) * 0.5), y: insets.top + UIScreenPixel), size: textSize)
        transition.setPosition(view: textContentsView, position: textFrame.origin)
        textContentsView.bounds = CGRect(origin: .zero, size: textFrame.size)

        if size.height != backgroundView.image?.size.height {
            backgroundView.image = generateStretchableFilledCircleImage(diameter: size.height, color: .white)?.withRenderingMode(.alwaysTemplate)
        }

        backgroundView.tintColor = background
        textContentsView.tintColor = foreground

        return size
    }
}
