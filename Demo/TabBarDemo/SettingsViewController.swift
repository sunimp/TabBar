//
//  SettingsViewController.swift
//  TabBarDemo
//
//  Created by Sun on 2026/4/21.
//

import UIKit

private struct SettingsSection {
    let items: [SettingsItem]
}

private enum SettingsDestination {
    case detail
    case appearance
}

private struct SettingsItem {
    let icon: String
    let iconColor: UIColor
    let title: String
    let detail: String?
    let hasDisclosure: Bool
    let destination: SettingsDestination
}

/// 「外观」二级页有实际内容，用未读红点提示；进入一次后视为已读（仅内存，重启 Demo 恢复）。
private var hasUnreadAppearance = true

private func makeDemoSettings(themeMode: DemoThemeMode) -> [SettingsSection] {
    [
        SettingsSection(items: [
            SettingsItem(icon: "star.fill", iconColor: .systemYellow, title: "Premium", detail: nil, hasDisclosure: true, destination: .detail),
        ]),
        SettingsSection(items: [
            SettingsItem(icon: "key.fill", iconColor: .systemOrange, title: "隐私与安全", detail: nil, hasDisclosure: true, destination: .detail),
            SettingsItem(icon: "bell.fill", iconColor: .systemRed, title: "通知和声音", detail: nil, hasDisclosure: true, destination: .detail),
            SettingsItem(icon: "iphone", iconColor: .systemGreen, title: "设备", detail: "2 台设备", hasDisclosure: true, destination: .detail),
            SettingsItem(icon: "folder.fill", iconColor: .systemBlue, title: "聊天文件夹", detail: nil, hasDisclosure: true, destination: .detail),
        ]),
        SettingsSection(items: [
            SettingsItem(icon: "paintbrush.fill", iconColor: .systemCyan, title: "外观", detail: themeMode.title, hasDisclosure: true, destination: .appearance),
            SettingsItem(icon: "textformat", iconColor: .systemPurple, title: "语言", detail: "简体中文", hasDisclosure: true, destination: .detail),
            SettingsItem(icon: "circle.lefthalf.filled", iconColor: .systemIndigo, title: "节能模式", detail: nil, hasDisclosure: true, destination: .detail),
        ]),
        SettingsSection(items: [
            SettingsItem(icon: "questionmark.circle.fill", iconColor: .systemBlue, title: "帮助", detail: nil, hasDisclosure: true, destination: .detail),
            SettingsItem(icon: "info.circle.fill", iconColor: .systemGray, title: "关于", detail: "v1.0.0", hasDisclosure: true, destination: .detail),
        ]),
        SettingsSection(items: [
            SettingsItem(icon: "arrow.triangle.2.circlepath", iconColor: .systemGreen, title: "数据与存储", detail: nil, hasDisclosure: true, destination: .detail),
            SettingsItem(icon: "lock.fill", iconColor: .systemOrange, title: "密码锁", detail: "已开启", hasDisclosure: true, destination: .detail),
            SettingsItem(icon: "hand.raised.fill", iconColor: .systemRed, title: "屏蔽名单", detail: "3 人", hasDisclosure: true, destination: .detail),
        ]),
    ]
}

final class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TabBarReselectHandling {
    /// 由 `SettingsSplitViewController` 设置，决定详情页显示在右栏还是 push；为 nil 时直接 push。
    var onShowDetail: ((UIViewController) -> Void)?
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var themeObserver: NSObjectProtocol?

    private var settingsSections: [SettingsSection] {
        makeDemoSettings(themeMode: DemoThemeController.shared.mode)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground

        title = "设置"

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        tableView.register(ProfileHeaderCell.self, forCellReuseIdentifier: "ProfileHeaderCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        // 表格嵌套在 TabBarController 内容容器中，系统无法自动识别，需显式声明供导航栏大标题跟随滚动。
        setContentScrollView(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // 双栏时列表不会因详情返回而重新出现，需监听外观切换刷新「外观」详情文字。
        themeObserver = NotificationCenter.default.addObserver(
            forName: DemoThemeController.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.tableView.reloadData()
        }
    }

    deinit {
        if let themeObserver {
            NotificationCenter.default.removeObserver(themeObserver)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    func handleTabBarReselect() {
        tableView.setContentOffset(.zero, animated: true)
    }

    func numberOfSections(in _: UITableView) -> Int {
        settingsSections.count + 1
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 1 }
        return settingsSections[section - 1].items.count
    }

    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0 ? 80.0 : 44.0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileHeaderCell", for: indexPath) as! ProfileHeaderCell
            cell.configure()
            return cell
        }

        let item = settingsSections[indexPath.section - 1].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        // valueCell：详情文字居右，与系统设置一致。
        var content = UIListContentConfiguration.valueCell()
        content.text = item.title
        content.secondaryText = item.detail
        if item.destination == .appearance, hasUnreadAppearance {
            content.secondaryAttributedText = Self.detailWithUnreadDot(item.detail)
        }
        content.image = Self.iconImage(systemName: item.icon, color: item.iconColor)
        content.imageProperties.maximumSize = Self.iconSize
        content.imageProperties.reservedLayoutSize = Self.iconSize
        // 行高固定 44pt，默认上下边距 15pt 会把图标压到 14pt，收窄以完整显示 29pt 图标。
        content.directionalLayoutMargins.top = 7.0
        content.directionalLayoutMargins.bottom = 7.0
        cell.accessoryType = item.hasDisclosure ? .disclosureIndicator : .none
        cell.contentConfiguration = content
        return cell
    }

    /// 详情文字后追加红点，位于文字与箭头之间，与系统设置的更新提示位置一致。
    private static func detailWithUnreadDot(_ detail: String?) -> NSAttributedString {
        let font = UIListContentConfiguration.valueCell().secondaryTextProperties.font
        let text = NSMutableAttributedString(string: detail.map { $0 + "  " } ?? "", attributes: [
            .font: font,
            .foregroundColor: UIColor.secondaryLabel,
        ])
        let dotSize: CGFloat = 8.0
        let dot = UIGraphicsImageRenderer(size: CGSize(width: dotSize, height: dotSize)).image { _ in
            UIColor.systemRed.setFill()
            UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: dotSize, height: dotSize)).fill()
        }
        let attachment = NSTextAttachment()
        attachment.image = dot
        // 垂直居中于文字 x-height 附近。
        attachment.bounds = CGRect(x: 0, y: (font.capHeight - dotSize) * 0.5, width: dotSize, height: dotSize)
        text.append(NSAttributedString(attachment: attachment))
        return text
    }

    /// 设置图标尺寸，与系统设置一致。
    private static let iconSize = CGSize(width: 29.0, height: 29.0)

    /// 生成白色符号 + 彩色圆角底的设置图标。
    ///
    /// 使用 `contentConfiguration` 时 `cell.imageView` 不参与渲染，需把底色直接绘制进图片。
    private static func iconImage(systemName: String, color: UIColor) -> UIImage? {
        let size = iconSize
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 16.0, weight: .medium)
        guard let symbol = UIImage(systemName: systemName, withConfiguration: symbolConfiguration)?
            .withTintColor(.white, renderingMode: .alwaysOriginal) else { return nil }
        return UIGraphicsImageRenderer(size: size).image { _ in
            color.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 7.0).fill()
            let symbolSize = symbol.size
            symbol.draw(in: CGRect(
                x: (size.width - symbolSize.width) * 0.5,
                y: (size.height - symbolSize.height) * 0.5,
                width: symbolSize.width,
                height: symbolSize.height
            ))
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section > 0 else { return }
        let item = settingsSections[indexPath.section - 1].items[indexPath.row]
        let detail: UIViewController
        switch item.destination {
        case .detail:
            detail = SettingsDetailViewController(title: item.title, subtitle: item.detail)
        case .appearance:
            detail = AppearanceSettingsViewController()
            if hasUnreadAppearance {
                hasUnreadAppearance = false
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
        if let onShowDetail {
            onShowDetail(detail)
        } else {
            navigationController?.pushViewController(detail, animated: true)
        }
    }
}

/// 设置列表 + 详情，布局规则见 `ListDetailSplitViewController`。
final class SettingsSplitViewController: ListDetailSplitViewController, TabBarReselectHandling {
    private let settingsList: SettingsViewController

    init() {
        let list = SettingsViewController()
        settingsList = list
        super.init(list: list, initialDetail: SettingsDetailViewController(title: "Premium", subtitle: nil))
        list.onShowDetail = { [weak self] detail in
            self?.showDetail(detail)
        }
    }

    func handleTabBarReselect() {
        settingsList.handleTabBarReselect()
    }
}

private final class ProfileHeaderCell: UITableViewCell {
    private let avatarView = UIView()
    private let initialLabel = UILabel()
    private let nameLabel = UILabel()
    private let phoneLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator

        avatarView.backgroundColor = .systemBlue
        avatarView.layer.cornerRadius = 30.0
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        initialLabel.text = "U"
        initialLabel.font = .systemFont(ofSize: 24.0, weight: .medium)
        initialLabel.textColor = .white
        initialLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(initialLabel)

        nameLabel.font = .systemFont(ofSize: 18.0, weight: .semibold)
        phoneLabel.font = .systemFont(ofSize: 14.0)
        phoneLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [nameLabel, phoneLabel])
        textStack.axis = .vertical
        textStack.spacing = 4.0
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(avatarView)
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16.0),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 60.0),
            avatarView.heightAnchor.constraint(equalToConstant: 60.0),

            initialLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 16.0),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32.0),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure() {
        nameLabel.text = "Demo User"
        phoneLabel.text = "+86 138 0000 0000"
    }
}

private final class AppearanceSettingsViewController: UITableViewController {
    private let modes = DemoThemeMode.allCases

    init() {
        super.init(style: .insetGrouped)
        title = "外观"
        navigationItem.largeTitleDisplayMode = .never
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AppearanceModeCell")
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        modes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AppearanceModeCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let mode = modes[indexPath.row]
        content.text = mode.title
        cell.contentConfiguration = content
        cell.accessoryType = DemoThemeController.shared.mode == mode ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        DemoThemeController.shared.setMode(modes[indexPath.row])
        tableView.reloadData()
    }
}

private final class SettingsDetailViewController: UIViewController {
    private let detailTitle: String
    private let detailSubtitle: String?

    init(title: String, subtitle: String?) {
        detailTitle = title
        detailSubtitle = subtitle
        super.init(nibName: nil, bundle: nil)
        self.title = title
        navigationItem.largeTitleDisplayMode = .never
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = detailTitle
        titleLabel.font = .systemFont(ofSize: 22.0, weight: .bold)

        let subtitleLabel = UILabel()
        subtitleLabel.text = detailSubtitle ?? "示例详情页"
        subtitleLabel.font = .systemFont(ofSize: 16.0)
        subtitleLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8.0
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
