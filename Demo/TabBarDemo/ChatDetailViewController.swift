//
//  ChatDetailViewController.swift
//  TabBarDemo
//
//  Created by Sun on 2026/4/21.
//

import UIKit

final class ChatDetailViewController: UIViewController {
    private let chatName: String
    private let color: UIColor

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let inputBar = UIView()

    init(chatName: String, color: UIColor) {
        self.chatName = chatName
        self.color = color
        super.init(nibName: nil, bundle: nil)
        title = chatName
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 8.0
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        inputBar.backgroundColor = .secondarySystemBackground
        inputBar.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        view.addSubview(inputBar)

        let textFieldBackground = UIView()
        textFieldBackground.backgroundColor = .systemBackground
        textFieldBackground.layer.cornerRadius = 18.0
        textFieldBackground.translatesAutoresizingMaskIntoConstraints = false

        let placeholderLabel = UILabel()
        placeholderLabel.text = "输入消息..."
        placeholderLabel.font = .systemFont(ofSize: 16.0)
        placeholderLabel.textColor = .placeholderText
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false

        let sendButton = UIImageView(image: UIImage(systemName: "arrow.up.circle.fill"))
        sendButton.tintColor = color
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        inputBar.addSubview(textFieldBackground)
        inputBar.addSubview(sendButton)
        textFieldBackground.addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16.0),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 12.0),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -12.0),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16.0),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -24.0),

            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            inputBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            inputBar.heightAnchor.constraint(equalToConstant: 52.0),

            textFieldBackground.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor, constant: 12.0),
            textFieldBackground.centerYAnchor.constraint(equalTo: inputBar.centerYAnchor),
            textFieldBackground.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -12.0),
            textFieldBackground.heightAnchor.constraint(equalToConstant: 36.0),

            placeholderLabel.leadingAnchor.constraint(equalTo: textFieldBackground.leadingAnchor, constant: 14.0),
            placeholderLabel.centerYAnchor.constraint(equalTo: textFieldBackground.centerYAnchor),

            sendButton.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor, constant: -12.0),
            sendButton.centerYAnchor.constraint(equalTo: inputBar.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 32.0),
            sendButton.heightAnchor.constraint(equalToConstant: 32.0),
        ])

        let messages: [(String, Bool)] = [
            ("你好！最近怎么样？", true),
            ("挺好的，在忙一个新项目", false),
            ("什么项目？", true),
            ("做一个自定义 TabBar 组件", false),
            ("听起来很有趣！", true),
            ("目标是做成一个真正可开源复用的 UIKit 组件", false),
            ("那现在效果如何？", true),
            ("已经很接近目标了", false),
            ("太好了", true),
        ]

        for (text, isIncoming) in messages {
            contentStack.addArrangedSubview(MessageBubbleView(text: text, isIncoming: isIncoming, accentColor: color))
        }
    }
}

private final class MessageBubbleView: UIView {
    init(text: String, isIncoming: Bool, accentColor: UIColor) {
        super.init(frame: .zero)

        let container = UIView()
        container.backgroundColor = isIncoming ? .secondarySystemBackground : accentColor.withAlphaComponent(0.15)
        container.layer.cornerRadius = 16.0
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 16.0)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        addSubview(container)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 8.0),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12.0),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12.0),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8.0),
            container.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.75),
        ])

        if isIncoming {
            container.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        } else {
            container.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
