import UIKit

class ConvoDetailTableViewDataSource: NSObject {
    private weak var convoManager: ConvoManaging?
    private weak var proxyManager: ProxyManaging?
    private weak var controller: UIViewController?

    func load(convoManager: ConvoManaging, proxyManager: ProxyManaging, controller: UIViewController) {
        self.convoManager = convoManager
        self.proxyManager = proxyManager
        self.controller = controller
    }
}

extension ConvoDetailTableViewDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.convoDetailReceiverProxyTableViewCell) as? ConvoDetailReceiverProxyTableViewCell,
                let convo = convoManager?.convo else {
                    return tableView.dequeueReusableCell(withIdentifier: Identifier.convoDetailReceiverProxyTableViewCell, for: indexPath)
            }
            cell.load(convo)
            cell.nicknameButton.addTarget(self, action: #selector(showEditReceiverNicknameAlert), for: .touchUpInside)
            return cell
        case 1:
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.convoDetailSenderProxyTableViewCell) as? SenderProxyTableViewCell,
                let proxy = proxyManager?.proxy else {
                    return tableView.dequeueReusableCell(withIdentifier: Identifier.convoDetailSenderProxyTableViewCell, for: indexPath)
            }
            cell.accessoryType = .disclosureIndicator
            cell.load(proxy)
            cell.nicknameButton.addTarget(self, action: #selector(showEditSenderNicknameAlert), for: .touchUpInside)
            cell.changeIconButton.addTarget(self, action: #selector(showIconPickerController), for: .touchUpInside)
            return cell
        case 2:
            let cell = UITableViewCell()
            switch indexPath.row {
            case 0:
                cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
                cell.textLabel?.text = "Leave conversation"
                cell.textLabel?.textColor = UIColor.red
                return cell
            case 1:
                cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
                cell.textLabel?.text = "Block user"
                cell.textLabel?.textColor = UIColor.red
                return cell
            default:
                break
            }
        default:
            break
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        case 2:
            return 2
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 2:
            return "Users are not notified when you take these actions."
        default:
            return nil
        }
    }
}

private extension ConvoDetailTableViewDataSource {
    @objc func showEditReceiverNicknameAlert() {
        guard let convo = convoManager?.convo else {
            return
        }
        let alert = UIAlertController(title: "Edit Receiver's Nickname", message: "Only you see this nickname.", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.autocapitalizationType = .sentences
            textField.autocorrectionType = .yes
            textField.clearButtonMode = .whileEditing
            textField.placeholder = "Enter A Nickname"
            textField.text = convo.receiverNickname
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { (action) in
            guard let nickname = alert.textFields?[0].text else {
                return
            }
            let trimmed = nickname.trimmingCharacters(in: CharacterSet(charactersIn: " "))
            if !(nickname != "" && trimmed == "") {
                DBConvo.setReceiverNickname(to: nickname, forConvo: convo) { (error) in
                    if let error = error, case .inputTooLong = error {
                        let alert = UIAlertController(title: "Nickname Too Long", message: "Please try a shorter nickname.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            self.showEditReceiverNicknameAlert()
                        })
                        self.controller?.present(alert, animated: true)
                    }
                }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        controller?.present(alert, animated: true)
    }

    @objc func showEditSenderNicknameAlert() {
        guard let proxy = proxyManager?.proxy else {
            return
        }
        controller?.showEditProxyNicknameAlert(proxy)
    }

    @objc func showIconPickerController() {
        guard let proxy = proxyManager?.proxy else {
            return
        }
        controller?.showIconPickerController(proxy)
    }
}
