import UIKit

class ProxyTableViewDataSource: NSObject {
    private let proxy: Proxy
    private var id: Int { return ObjectIdentifier(self).hashValue }
    private weak var tableViewController: UITableViewController?
    private weak var convosObserver: ConvosObserver?
    private weak var proxyObserver: ProxyObserver?

    init(proxy: Proxy, tableViewController: UITableViewController) {
        self.proxy = proxy
        super.init()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        convosObserver = appDelegate?.convosObserver
        proxyObserver = appDelegate?.proxyObserver
        self.tableViewController = tableViewController
        tableViewController.tableView.dataSource = self
    }

    func observe() {
        guard let tableView = tableViewController?.tableView else { return }
        convosObserver?.observeConvos(owner: proxy.key, tableView: tableView)
        proxyObserver?.observe(proxy: proxy, tableView: tableView)
    }

    func stopObserving() {
        convosObserver?.stopObserving()
        proxyObserver?.stopObserving()
    }
}

extension ProxyTableViewDataSource: UITableViewDataSource {
    var convos: [Convo] {
        return convosObserver?.convos ?? []
    }

    var freshProxy: Proxy? {
        return proxyObserver?.getProxy(forKey: proxy.key)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.senderProxyTableViewCell) as? SenderProxyTableViewCell,
                let proxy = freshProxy else {
                    return tableView.dequeueReusableCell(withIdentifier: Identifier.senderProxyTableViewCell, for: indexPath)
            }
            cell.configure(proxy)
            cell.changeIconButton.addTarget(self, action: #selector(self.goToIconPickerVC), for: .touchUpInside)
            cell.nicknameButton.addTarget(self, action: #selector(self.editNickname), for: .touchUpInside)
            return cell
        case 1:
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.convosTableViewCell) as? ConvosTableViewCell,
                let convo = convos[safe: indexPath.row] else {
                    return tableView.dequeueReusableCell(withIdentifier: Identifier.convosTableViewCell, for: indexPath)
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
        guard let proxy = freshProxy else { return }
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
        tableViewController?.present(alert, animated: true, completion: nil)
    }

    @objc func goToIconPickerVC() {
        guard
            let proxy = freshProxy,
            let iconPickerCollectionViewController = tableViewController?.storyboard?.instantiateViewController(withIdentifier: Identifier.iconPickerCollectionViewController) as? IconPickerCollectionViewController else {
                return
        }
        iconPickerCollectionViewController.proxy = proxy
        tableViewController?.navigationController?.pushViewController(iconPickerCollectionViewController, animated: true)
    }
}
