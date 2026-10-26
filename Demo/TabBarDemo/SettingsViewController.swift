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
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

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

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
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
        var content = cell.defaultContentConfiguration()
        content.text = item.title
        content.secondaryText = item.detail
        content.image = UIImage(systemName: item.icon)
        content.imageProperties.tintColor = .white
        cell.accessoryType = item.hasDisclosure ? .disclosureIndicator : .none
        cell.contentConfiguration = content
        cell.imageView?.backgroundColor = item.iconColor
        cell.imageView?.layer.cornerRadius = 6.0
        cell.imageView?.clipsToBounds = true
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section > 0 else { return }
        let item = settingsSections[indexPath.section - 1].items[indexPath.row]
        switch item.destination {
        case .detail:
            navigationController?.pushViewController(SettingsDetailViewController(title: item.title, subtitle: item.detail), animated: true)
        case .appearance:
            navigationController?.pushViewController(AppearanceSettingsViewController(), animated: true)
        }
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
