//
//  ChatListViewController.swift
//  TabBarDemo
//
//  Created by Sun on 2026/4/21.
//

import UIKit

private struct ChatItem {
    let name: String
    let avatar: String
    let lastMessage: String
    let time: String
    let unread: Int
    let color: UIColor
}

private let demoChats: [ChatItem] = {
    let base: [ChatItem] = [
        ChatItem(name: "通知", avatar: "bell.fill", lastMessage: "您有 3 条新消息", time: "刚刚", unread: 3, color: .systemBlue),
        ChatItem(name: "Alice", avatar: "person.fill", lastMessage: "明天一起吃午饭？", time: "12:30", unread: 1, color: .systemPink),
        ChatItem(name: "工作群", avatar: "person.3.fill", lastMessage: "Bob: 报告已提交", time: "11:45", unread: 0, color: .systemGreen),
        ChatItem(name: "Bob", avatar: "person.fill", lastMessage: "👍", time: "昨天", unread: 0, color: .systemOrange),
        ChatItem(name: "家庭群", avatar: "house.fill", lastMessage: "妈妈: 周末回家吗？", time: "昨天", unread: 5, color: .systemRed),
        ChatItem(name: "Charlie", avatar: "person.fill", lastMessage: "那个项目进展如何？", time: "周一", unread: 0, color: .systemPurple),
        ChatItem(name: "读书会", avatar: "book.fill", lastMessage: "本周推荐：三体", time: "周日", unread: 0, color: .systemTeal),
        ChatItem(name: "Dave", avatar: "person.fill", lastMessage: "[照片]", time: "3/25", unread: 0, color: .systemIndigo),
        ChatItem(name: "运动群", avatar: "figure.run", lastMessage: "Eve: 周六打球吗？", time: "3/24", unread: 0, color: .systemMint),
        ChatItem(name: "Saved Messages", avatar: "bookmark.fill", lastMessage: "记录一些笔记...", time: "3/20", unread: 0, color: .systemCyan),
        ChatItem(name: "Frank", avatar: "person.fill", lastMessage: "收到，谢谢", time: "3/18", unread: 0, color: .systemBrown),
        ChatItem(name: "设计群", avatar: "paintbrush.fill", lastMessage: "新版 UI 稿已上传", time: "3/17", unread: 2, color: .systemIndigo),
        ChatItem(name: "Grace", avatar: "person.fill", lastMessage: "周末去爬山吗？", time: "3/15", unread: 0, color: .systemPink),
        ChatItem(name: "技术分享", avatar: "laptopcomputer", lastMessage: "Swift 6 并发新特性", time: "3/14", unread: 0, color: .systemBlue),
        ChatItem(name: "Helen", avatar: "person.fill", lastMessage: "生日快乐！🎂", time: "3/12", unread: 0, color: .systemRed),
        ChatItem(name: "旅行群", avatar: "airplane", lastMessage: "五一去哪玩？", time: "3/10", unread: 8, color: .systemOrange),
        ChatItem(name: "Ivan", avatar: "person.fill", lastMessage: "代码已合并", time: "3/8", unread: 0, color: .systemGreen),
        ChatItem(name: "音乐群", avatar: "music.note", lastMessage: "推荐一首新歌", time: "3/6", unread: 0, color: .systemPurple),
        ChatItem(name: "Julia", avatar: "person.fill", lastMessage: "文档发你了", time: "3/4", unread: 0, color: .systemTeal),
        ChatItem(name: "Kevin", avatar: "person.fill", lastMessage: "明天开会别忘了", time: "3/2", unread: 1, color: .systemMint),
    ]
    return base
}()

final class ChatListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TabBarReselectHandling, TabBarDoubleTapHandling {
    private let tableView = UITableView(frame: .zero, style: .plain)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        title = "聊天 \(demoChats.count)"

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatCell.self, forCellReuseIdentifier: "ChatCell")
        tableView.rowHeight = 72.0
        tableView.separatorInset = UIEdgeInsets(top: 0.0, left: 76.0, bottom: 0.0, right: 0.0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func handleTabBarReselect() {
        tableView.setContentOffset(.zero, animated: true)
    }

    func handleTabBarDoubleTap() {
        let alert = UIAlertController(title: "双击触发", message: "双击了「聊天」标签", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        demoChats.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatCell
        cell.configure(with: demoChats[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let chat = demoChats[indexPath.row]
        let detail = ChatDetailViewController(chatName: chat.name, color: chat.color)
        navigationController?.pushViewController(detail, animated: true)
    }
}

private final class ChatCell: UITableViewCell {
    private let avatarView = UIView()
    private let avatarIconView = UIImageView()
    private let nameLabel = UILabel()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let badgeLabel = PaddingLabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        avatarView.layer.cornerRadius = 24.0
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        avatarIconView.tintColor = .white
        avatarIconView.contentMode = .scaleAspectFit
        avatarIconView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(avatarIconView)

        nameLabel.font = .systemFont(ofSize: 16.0, weight: .semibold)
        messageLabel.font = .systemFont(ofSize: 15.0)
        messageLabel.textColor = .secondaryLabel
        timeLabel.font = .systemFont(ofSize: 13.0)
        timeLabel.textColor = .tertiaryLabel

        badgeLabel.font = .systemFont(ofSize: 13.0, weight: .medium)
        badgeLabel.textColor = .white
        badgeLabel.backgroundColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        badgeLabel.layer.cornerRadius = 10.0
        badgeLabel.clipsToBounds = true
        badgeLabel.textAlignment = .center
        badgeLabel.contentInsets = UIEdgeInsets(top: 0.0, left: 6.0, bottom: 0.0, right: 6.0)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [nameLabel, messageLabel])
        textStack.axis = .vertical
        textStack.spacing = 4.0
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let trailingStack = UIStackView(arrangedSubviews: [timeLabel, badgeLabel])
        trailingStack.axis = .vertical
        trailingStack.alignment = .trailing
        trailingStack.spacing = 8.0
        trailingStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(avatarView)
        contentView.addSubview(textStack)
        contentView.addSubview(trailingStack)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12.0),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 48.0),
            avatarView.heightAnchor.constraint(equalToConstant: 48.0),

            avatarIconView.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarIconView.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            avatarIconView.widthAnchor.constraint(equalToConstant: 24.0),
            avatarIconView.heightAnchor.constraint(equalToConstant: 24.0),

            trailingStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12.0),
            trailingStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14.0),

            textStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12.0),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingStack.leadingAnchor, constant: -12.0),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            badgeLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20.0),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with chat: ChatItem) {
        avatarView.backgroundColor = chat.color
        avatarIconView.image = UIImage(systemName: chat.avatar)
        nameLabel.text = chat.name
        messageLabel.text = chat.lastMessage
        timeLabel.text = chat.time
        if chat.unread > 0 {
            badgeLabel.text = "\(chat.unread)"
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
    }
}

private final class PaddingLabel: UILabel {
    var contentInsets: UIEdgeInsets = .zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }
}
