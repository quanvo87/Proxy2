class ProxyInfoTableViewDataSource: NSObject, UITableViewDataSource {
    private let convosObserver = ConvosObserver()
    private let proxyObserver = ProxyObserver()
    private weak var tableViewController: UITableViewController?

    var convos: [Convo] {
        return convosObserver.convos
    }

    var proxy: Proxy {
        return proxyObserver.proxy
    }

    override init() {}

    func observe(proxy: Proxy, tableViewController: UITableViewController) {
        convosObserver.observeConvos(forOwner: proxy.ownerId, tableView: tableViewController.tableView)
        proxyObserver.observe(proxy, tableView: tableViewController.tableView)
        self.tableViewController = tableViewController
    }
}

extension ProxyInfoTableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.SenderProxyInfoCell, for: indexPath) as? SenderProxyInfoCell else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.SenderProxyInfoCell, for: indexPath)
            }

            cell.changeIconButton.addTarget(self, action: #selector(self.goToIconPickerVC), for: .touchUpInside)
            cell.iconImageView.image = nil
            cell.nameLabel.text = proxy.name
            cell.nicknameButton.addTarget(self, action: #selector(self.editNickname), for: .touchUpInside)
            cell.nicknameButton.setTitle(proxy.nickname == "" ? "Enter A Nickname" : proxy.nickname, for: .normal)
            cell.selectionStyle = .none

            DBProxy.getImageForIcon(proxy.icon, tag: 0) { (result) in
                guard let (image, _) = result else {
                    return
                }
                DispatchQueue.main.async {
                    cell.iconImageView.image = image
                }
            }

            return cell

        case 1:
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.ConvoCell, for: indexPath) as? ConvoCell,
                let convo = convos[safe: indexPath.row] else {
                    return tableView.dequeueReusableCell(withIdentifier: Identifier.ConvoCell, for: indexPath)
            }

            cell.iconImageView.image = nil
            cell.lastMessageLabel.text = convo.lastMessage
            cell.timestampLabel.text = convo.timestamp.asTimeAgo
            cell.titleLabel.attributedText = DBConvo.makeConvoTitle(receiverNickname: convo.receiverNickname, receiverProxyName: convo.senderProxyName, senderNickname: convo.senderNickname, senderProxyName: convo.senderProxyName)
            cell.unreadLabel.text = convo.unreadCount.asLabel

            DBProxy.getImageForIcon(convo.receiverIcon, tag: cell.tag) { (result) in
                guard let (image, tag) = result else { return }
                DispatchQueue.main.async {
                    guard tag == cell.tag else { return }
                    cell.iconImageView.image = image
                }
            }

            return cell

        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return convos.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return "CONVERSATIONS"
        default:
            return nil
        }
    }
}

private extension ProxyInfoTableViewDataSource {
    @objc func editNickname() {
        let alert = UIAlertController(title: "Edit Nickname", message: "Only you see your nickname.", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.autocapitalizationType = .sentences
            textField.autocorrectionType = .yes
            textField.clearButtonMode = .whileEditing
            textField.placeholder = "Enter A Nickname"
            textField.text = self.proxy.nickname
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { (action) in
            guard let nickname = alert.textFields?[0].text else { return }
            let trim = nickname.trimmingCharacters(in: CharacterSet(charactersIn: " "))
            if !(nickname != "" && trim == "") {
                DBProxy.setNickname(to: nickname, forProxy: self.proxy) { _ in }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        tableViewController?.present(alert, animated: true, completion: nil)
    }

    @objc func goToIconPickerVC() {
        guard let iconPickerCollectionViewController = tableViewController?.storyboard?.instantiateViewController(withIdentifier: Identifier.IconPickerCollectionViewController) as? IconPickerCollectionViewController else { return }
        iconPickerCollectionViewController.proxy = proxy
        tableViewController?.navigationController?.pushViewController(iconPickerCollectionViewController, animated: true)
    }
}
