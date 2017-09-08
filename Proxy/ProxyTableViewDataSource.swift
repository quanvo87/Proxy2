import UIKit

class ProxyTableViewDataSource: NSObject, UITableViewDataSource {
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
        tableViewController.tableView.dataSource = self
    }
}

extension ProxyTableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.senderProxyTableViewCell, for: indexPath) as? SenderProxyTableViewCell else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.senderProxyTableViewCell, for: indexPath)
            }

            cell.changeIconButton.addTarget(self, action: #selector(self.goToIconPickerVC), for: .touchUpInside)
            cell.iconImageView.image = nil
            cell.nameLabel.text = proxy.name
            cell.nicknameButton.addTarget(self, action: #selector(self.editNickname), for: .touchUpInside)
            cell.nicknameButton.setTitle(proxy.nickname == "" ? "Enter A Nickname" : proxy.nickname, for: .normal)
            cell.selectionStyle = .none

            DBProxy.getImageForIcon(proxy.icon) { (result) in
                guard let (icon, image) = result else { return }
                DispatchQueue.main.async {
                    guard icon == self.proxy.icon else { return }
                    cell.iconImageView.image = image
                }
            }

            return cell

        case 1:
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.convosTableViewCell, for: indexPath) as? ConvosTableViewCell,
                let convo = convos[safe: indexPath.row] else {
                    return tableView.dequeueReusableCell(withIdentifier: Identifier.convosTableViewCell, for: indexPath)
            }

            cell.iconImageView.image = nil
            cell.lastMessageLabel.text = convo.lastMessage
            cell.timestampLabel.text = convo.timestamp.asTimeAgo
            cell.titleLabel.attributedText = DBConvo.makeConvoTitle(receiverNickname: convo.receiverNickname, receiverProxyName: convo.senderProxyName, senderNickname: convo.senderNickname, senderProxyName: convo.senderProxyName)
            cell.unreadLabel.text = nil // TODO: delete

            DBProxy.getImageForIcon(convo.receiverIcon) { (result) in
                guard let (icon, image) = result else { return }
                DispatchQueue.main.async {
                    guard icon == convo.receiverIcon else { return }
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

private extension ProxyTableViewDataSource {
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
        guard let iconPickerCollectionViewController = tableViewController?.storyboard?.instantiateViewController(withIdentifier: Identifier.iconPickerCollectionViewController) as? IconPickerCollectionViewController else { return }
        iconPickerCollectionViewController.proxy = proxy
        tableViewController?.navigationController?.pushViewController(iconPickerCollectionViewController, animated: true)
    }
}
