//
//  ContactsViewController.swift
//  TabBarDemo
//
//  Created by Sun on 2026/4/21.
//

import UIKit

private struct ContactSection {
    let letter: String
    let contacts: [Contact]
}

private struct Contact {
    let name: String
    let status: String
    let color: UIColor
}

private let demoSections: [ContactSection] = [
    ContactSection(letter: "A", contacts: [
        Contact(name: "Alice", status: "最近在线", color: .systemPink),
        Contact(name: "Andrew", status: "3 小时前", color: .systemBlue),
        Contact(name: "Amy", status: "在线", color: .systemCyan),
        Contact(name: "Aaron", status: "昨天", color: .systemMint),
    ]),
    ContactSection(letter: "B", contacts: [
        Contact(name: "Bob", status: "在线", color: .systemOrange),
        Contact(name: "Bella", status: "昨天", color: .systemPurple),
        Contact(name: "Ben", status: "5 小时前", color: .systemBrown),
    ]),
    ContactSection(letter: "C", contacts: [
        Contact(name: "Charlie", status: "在线", color: .systemGreen),
        Contact(name: "Claire", status: "一周前", color: .systemTeal),
        Contact(name: "Chris", status: "最近在线", color: .systemIndigo),
        Contact(name: "Cathy", status: "在线", color: .systemPink),
    ]),
    ContactSection(letter: "D", contacts: [
        Contact(name: "Dave", status: "3 天前", color: .systemIndigo),
        Contact(name: "Diana", status: "在线", color: .systemRed),
        Contact(name: "Daniel", status: "昨天", color: .systemBlue),
    ]),
    ContactSection(letter: "E", contacts: [
        Contact(name: "Eve", status: "在线", color: .systemMint),
        Contact(name: "Emily", status: "2 小时前", color: .systemOrange),
        Contact(name: "Ethan", status: "一周前", color: .systemGreen),
    ]),
    ContactSection(letter: "F", contacts: [
        Contact(name: "Frank", status: "昨天", color: .systemBrown),
        Contact(name: "Fiona", status: "在线", color: .systemCyan),
    ]),
    ContactSection(letter: "G", contacts: [
        Contact(name: "Grace", status: "最近在线", color: .systemPink),
        Contact(name: "George", status: "3 天前", color: .systemBlue),
    ]),
    ContactSection(letter: "H", contacts: [
        Contact(name: "Helen", status: "在线", color: .systemRed),
        Contact(name: "Henry", status: "昨天", color: .systemPurple),
    ]),
    ContactSection(letter: "I", contacts: [
        Contact(name: "Ivan", status: "在线", color: .systemGreen),
        Contact(name: "Iris", status: "5 小时前", color: .systemTeal),
    ]),
    ContactSection(letter: "J", contacts: [
        Contact(name: "Julia", status: "最近在线", color: .systemTeal),
        Contact(name: "Jack", status: "在线", color: .systemOrange),
        Contact(name: "Jane", status: "昨天", color: .systemIndigo),
    ]),
    ContactSection(letter: "K", contacts: [
        Contact(name: "Kevin", status: "在线", color: .systemMint),
        Contact(name: "Karen", status: "2 天前", color: .systemPink),
    ]),
]

final class ContactsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TabBarReselectHandling {
    private let navBar = NavigationBarView()
    private let tableView = UITableView(frame: .zero, style: .plain)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        navBar.title = "联系人"
        navBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navBar)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ContactCell.self, forCellReuseIdentifier: "ContactCell")
        tableView.rowHeight = 56.0
        tableView.sectionIndexColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func handleTabBarReselect() {
        tableView.setContentOffset(.zero, animated: true)
    }

    func numberOfSections(in _: UITableView) -> Int {
        demoSections.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        demoSections[section].contacts.count
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        demoSections[section].letter
    }

    func sectionIndexTitles(for _: UITableView) -> [String]? {
        demoSections.map(\.letter)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! ContactCell
        cell.configure(with: demoSections[indexPath.section].contacts[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

private final class ContactCell: UITableViewCell {
    private let avatarView = UIView()
    private let initialLabel = UILabel()
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        avatarView.layer.cornerRadius = 20.0
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        initialLabel.font = .systemFont(ofSize: 16.0, weight: .medium)
        initialLabel.textColor = .white
        initialLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(initialLabel)

        nameLabel.font = .systemFont(ofSize: 16.0)
        statusLabel.font = .systemFont(ofSize: 13.0)
        statusLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [nameLabel, statusLabel])
        textStack.axis = .vertical
        textStack.spacing = 4.0
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(avatarView)
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12.0),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 40.0),
            avatarView.heightAnchor.constraint(equalToConstant: 40.0),

            initialLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12.0),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12.0),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with contact: Contact) {
        avatarView.backgroundColor = contact.color
        initialLabel.text = String(contact.name.prefix(1))
        nameLabel.text = contact.name
        statusLabel.text = contact.status
        statusLabel.textColor = contact.status == "在线" ? .systemGreen : .secondaryLabel
    }
}
