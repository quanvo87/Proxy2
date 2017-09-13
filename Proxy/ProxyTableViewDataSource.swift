import UIKit

class ProxyTableViewDataSource: NSObject {
    private let proxyKey: String
    private weak var tableViewController: UITableViewController?
    private weak var convosObserver: ConvosObserver?
    private weak var proxyObserver: ProxyObserver?

    private var id: Int {
        return ObjectIdentifier(self).hashValue
    }

    init(proxy: Proxy, tableViewController: UITableViewController) {
        proxyKey = proxy.key
        super.init()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        convosObserver = appDelegate?.convosObserver
        convosObserver?.tableViews.setObject(tableViewController.tableView, forKey: id as AnyObject)
        convosObserver?.observeConvos(forOwner: proxy.key)
        proxyObserver = appDelegate?.proxyObserver
        proxyObserver?.tableViews.setObject(tableViewController.tableView, forKey: id as AnyObject)
        proxyObserver?.observe(proxy)
        self.tableViewController = tableViewController
        tableViewController.tableView.dataSource = self
    }

    deinit {
        convosObserver?.tableViews.removeObject(forKey: id as AnyObject)
        proxyObserver?.tableViews.removeObject(forKey: id as AnyObject)
    }
}

extension ProxyTableViewDataSource: UITableViewDataSource {
    var convos: [Convo] {
        return convosObserver?.convos ?? []
    }

    var proxy: Proxy? {
        return proxyObserver?.proxies.object(forKey: proxyKey as NSString) as? Proxy
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.senderProxyTableViewCell) as? SenderProxyTableViewCell,
                let proxy = proxy else {
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
        tableViewController?.present(alert, animated: true, completion: nil)
    }

    @objc func goToIconPickerVC() {
        guard
            let proxy = proxy,
            let iconPickerCollectionViewController = tableViewController?.storyboard?.instantiateViewController(withIdentifier: Identifier.iconPickerCollectionViewController) as? IconPickerCollectionViewController else {
                return
        }
        iconPickerCollectionViewController.proxy = proxy
        tableViewController?.navigationController?.pushViewController(iconPickerCollectionViewController, animated: true)
    }
}
