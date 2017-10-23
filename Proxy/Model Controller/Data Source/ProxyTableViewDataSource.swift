import UIKit

class ProxyTableViewDataSource: NSObject {
    private weak var controller: UIViewController?
    private weak var convosManager: ConvosManaging?
    private weak var proxyManager: ProxyManaging?

    func load(controller: UIViewController, convosManager: ConvosManaging, proxyManager: ProxyManaging) {
        self.controller = controller
        self.convosManager = convosManager
        self.proxyManager = proxyManager
    }
}

extension ProxyTableViewDataSource: UITableViewDataSource {
    var convos: [Convo] {
        return convosManager?.convos ?? []
    }

    var proxy: Proxy? {
        return proxyManager?.proxy
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: Name.senderProxyTableViewCell) as? SenderProxyTableViewCell,
                let proxy = proxy else {
                    return tableView.dequeueReusableCell(withIdentifier: Name.senderProxyTableViewCell, for: indexPath)
            }
            cell.configure(proxy)
            cell.changeIconButton.addTarget(self, action: #selector(showIconPickerController), for: .touchUpInside)
            cell.nicknameButton.addTarget(self, action: #selector(editNickname), for: .touchUpInside)
            return cell
        case 1:
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: Name.convosTableViewCell) as? ConvosTableViewCell,
                let convo = convos[safe: indexPath.row] else {
                    return tableView.dequeueReusableCell(withIdentifier: Name.convosTableViewCell, for: indexPath)
            }
            cell.configure(convo)
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return convos.count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return "CONVERSATIONS"
        default: return nil
        }
    }
}

private extension ProxyTableViewDataSource {
    @objc func editNickname() {
        guard let proxy = proxy else { return }
        let alert = UIAlertController(title: "Edit Nickname", message: "Only you see your nickname.", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.autocapitalizationType = .sentences
            textField.autocorrectionType = .yes
            textField.clearButtonMode = .whileEditing
            textField.placeholder = "Enter A Nickname"
            textField.text = proxy.nickname
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { (action) in
            guard let nickname = alert.textFields?[0].text else { return }
            let trim = nickname.trimmingCharacters(in: CharacterSet(charactersIn: " "))
            if !(nickname != "" && trim == "") {
                DBProxy.setNickname(to: nickname, forProxy: proxy) { _ in }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        controller?.present(alert, animated: true, completion: nil)
    }

    @objc func showIconPickerController() {
        guard
            let proxy = proxy,
            let iconPickerCollectionViewController = controller?.storyboard?.instantiateViewController(withIdentifier: Name.iconPickerCollectionViewController) as? IconPickerCollectionViewController else {
                return
        }
        iconPickerCollectionViewController.proxy = proxy
        let navigationController = UINavigationController(rootViewController: iconPickerCollectionViewController)
        controller?.present(navigationController, animated: true)
    }
}
