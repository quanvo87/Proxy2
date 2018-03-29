import UIKit

class ConvoDetailViewController: UIViewController {
    private let convoObserver: ConvoObserving
    private let database: Database
    private let proxyObserver: ProxyObsering
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var convo: Convo? { didSet { didSetConvo() } }
    private var proxy: Proxy?
    private var shouldClose = false

    init(convoObserver: ConvoObserving = ConvoObserver(),
         database: Database = Shared.database,
         proxyObserver: ProxyObsering = ProxyObserver(),
         convo: Convo) {
        self.convoObserver = convoObserver
        self.database = database
        self.proxyObserver = proxyObserver
        self.convo = convo

        super.init(nibName: nil, bundle: nil)

        convoObserver.observe(convoSenderId: convo.senderId, convoKey: convo.key) { [weak self] convo in
            self?.convo = convo
        }

        let activityIndicatorView = UIActivityIndicatorView(view)
        proxyObserver.observe(proxyOwnerId: convo.senderId, proxyKey: convo.senderProxyKey) { [weak self] proxy in
            activityIndicatorView.removeFromSuperview()
            self?.proxy = proxy
            if proxy == nil {
                self?.shouldClose = true
            } else {
                self?.tableView.reloadData()
            }
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.delaysContentTouches = false
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(
            UINib(nibName: String(describing: BasicTableViewCell.self), bundle: nil),
            forCellReuseIdentifier: String(describing: BasicTableViewCell.self)
        )
        tableView.register(
            UINib(nibName: String(describing: ConvoDetailReceiverProxyTableViewCell.self), bundle: nil),
            forCellReuseIdentifier: String(describing: ConvoDetailReceiverProxyTableViewCell.self)
        )
        tableView.register(
            UINib(nibName: Constant.convoDetailSenderProxyTableViewCell, bundle: nil),
            forCellReuseIdentifier: Constant.convoDetailSenderProxyTableViewCell
        )
        tableView.setDelaysContentTouchesForScrollViews()

        view.addSubview(tableView)

        activityIndicatorView.startAnimatingAndBringToFront()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if shouldClose {
            _ = navigationController?.popViewController(animated: false)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ConvoDetailViewController {
    func didSetConvo() {
        if convo == nil {
            shouldClose = true
        } else {
            tableView.reloadData()
        }
    }
}

// MARK: - UITableViewDataSource
extension ConvoDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let convo = convo, let cell = tableView.dequeueReusableCell(
                withIdentifier: String(describing: ConvoDetailReceiverProxyTableViewCell.self)
                ) as? ConvoDetailReceiverProxyTableViewCell else {
                    return ConvoDetailReceiverProxyTableViewCell()
            }
            cell.load(convo)
            cell.nicknameButton.addTarget(self, action: #selector(showEditReceiverNicknameAlert), for: .touchUpInside)
            return cell
        case 1:
            guard let proxy = proxy, let cell = tableView.dequeueReusableCell(
                withIdentifier: Constant.convoDetailSenderProxyTableViewCell
                ) as? SenderProxyTableViewCell else {
                    return SenderProxyTableViewCell()
            }
            cell.accessoryType = .disclosureIndicator
            cell.changeIconButton.addTarget(self, action: #selector(_showIconPickerController), for: .touchUpInside)
            cell.load(proxy)
            cell.nicknameButton.addTarget(self, action: #selector(showEditSenderNicknameAlert), for: .touchUpInside)
            return cell
        case 2:
            guard let convo = convo, let cell = tableView.dequeueReusableCell(
                withIdentifier: String(describing: BasicTableViewCell.self)
                ) as? BasicTableViewCell else {
                    return BasicTableViewCell()
            }
            switch indexPath.row {
            case 0:
                cell.load(icon: "blockUser")
                cell.titleLabel.text = convo.receiverIsBlocked ? "Unblock User" : "Block User"
                cell.titleLabel.textColor = convo.receiverIsBlocked ? .black : .red
            case 1:
                cell.load(icon: "delete", title: "Delete Proxy")
                cell.titleLabel.textColor = .red
            default:
                break
            }
            return cell
        default:
            break
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 2:
            return 2
        default:
            return 1
        }
    }

    @objc private func showEditReceiverNicknameAlert() {
        guard let convo = convo else {
            return
        }
        let alert = UIAlertController(
            title: "Edit Receiver's Nickname",
            message: "Only you see this nickname.",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.autocapitalizationType = .sentences
            textField.autocorrectionType = .yes
            textField.clearButtonMode = .whileEditing
            textField.placeholder = "Enter A Nickname"
            textField.text = convo.receiverNickname
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let nickname = alert?.textFields?[0].text else {
                return
            }
            let trimmed = nickname.trimmed
            if !(nickname != "" && trimmed == "") {
                self?.database.setReceiverNickname(to: nickname, for: convo) { error in
                    if let error = error {
                        StatusBar.showErrorStatusBarBanner(error)
                    }
                }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func showEditSenderNicknameAlert() {
        guard let proxy = proxy else {
            return
        }
        showEditProxyNicknameAlert(proxy)
    }

    @objc private func _showIconPickerController() {
        guard let proxy = proxy else {
            return
        }
        showIconPickerViewController(proxy)
    }
}

// MARK: - UITableViewDelegate
extension ConvoDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let convo = convo, let proxy = proxy else {
            return
        }
        switch indexPath.section {
        case 1:
            showProxyViewController(proxy)
        case 2:
            switch indexPath.row {
            case 0:
                if convo.receiverIsBlocked {
                    let blockedUser = BlockedUser(convo: convo)
                    database.unblock(blockedUser) { error in
                        if let error = error {
                            StatusBar.showErrorStatusBarBanner(error)
                        } else {
                            StatusBar.showSuccessStatusBarBanner(
                                "The owner for \(convo.receiverProxyName) has been unblocked."
                            )
                        }
                    }
                } else {
                    let alert = Alert.make(
                        title: "Block User?",
                        message: "They will not be able to message you."
                    )
                    alert.addAction(Alert.makeDestructiveAction(title: "Block") { [weak self] _ in
                        guard let convo = self?.convo else {
                            return
                        }
                        let blockedUser = BlockedUser(convo: convo)
                        self?.database.block(blockedUser) { error in
                            if let error = error {
                                StatusBar.showErrorStatusBarBanner(error)
                            } else {
                                StatusBar.showSuccessStatusBarBanner(
                                    "The owner for \(convo.receiverProxyName) has been blocked."
                                )
                            }
                        }
                    })
                    alert.addAction(Alert.makeCancelAction())
                    present(alert, animated: true)
                }
            case 1:
                let alert = Alert.make(
                    title: Alert.deleteProxyMessage.title,
                    message: Alert.deleteProxyMessage.message
                )
                alert.addAction(Alert.makeDestructiveAction(title: "Delete") { [weak self] _ in
                    self?.database.delete(proxy) { error in
                        if let error = error {
                            StatusBar.showErrorStatusBarBanner(error)
                        } else {
                            StatusBar.showSuccessStatusBarBanner("\(proxy.name) has been deleted.")
                        }
                    }
                })
                alert.addAction(Alert.makeCancelAction())
                present(alert, animated: true)
            default:
                return
            }
        default:
            return
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 80
        case 1:
            return 80
        default:
            return UITableViewAutomaticDimension
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 15
        case 1:
            return 15
        default:
            return UITableViewAutomaticDimension
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch section {
        case 0:
            let view = UIView()
            let label = UILabel(frame: CGRect(x: 15, y: 0, width: tableView.frame.width, height: 30))
            label.font = label.font.withSize(13)
            label.text = "Them"
            label.textColor = .gray
            view.addSubview(label)
            return view
        case 1:
            let view = UIView()
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.frame.width - 15, height: 30))
            label.autoresizingMask = .flexibleRightMargin
            label.font = label.font.withSize(13)
            label.text = "You"
            label.textAlignment = .right
            label.textColor = .gray
            view.addSubview(label)
            return view
        default:
            return nil
        }
    }
}
