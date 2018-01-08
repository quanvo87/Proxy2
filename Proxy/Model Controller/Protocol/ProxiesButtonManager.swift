import UIKit
import ViewGlower

class ProxiesButtonManager: ButtonManaging {
    let viewGlower = ViewGlower()
    var cancelButton = UIBarButtonItem()
    var confirmButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    var makeNewMessageButton = UIBarButtonItem()
    var makeNewProxyButton = UIBarButtonItem()
    private var uid: String?
    private weak var controller: UIViewController?
    private weak var delegate: MakeNewMessageDelegate?
    private weak var itemsToDeleteManager: ItemsToDeleteManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var proxyKeysManager: ProxyKeysManaging?
    private weak var tableView: UITableView?

    func load(uid: String,
              controller: UIViewController,
              delegate: MakeNewMessageDelegate,
              itemsToDeleteManager: ItemsToDeleteManaging,
              proxiesManager: ProxiesManaging,
              proxyKeysManager: ProxyKeysManaging,
              tableView: UITableView) {
        self.uid = uid
        self.controller = controller
        self.delegate = delegate
        self.itemsToDeleteManager = itemsToDeleteManager
        self.proxiesManager = proxiesManager
        self.proxyKeysManager = proxyKeysManager
        self.tableView = tableView
        makeButtons()
        setDefaultButtons()
    }
}

private extension ProxiesButtonManager {
    func makeButtons() {
        cancelButton = UIBarButtonItem.make(target: self, action: #selector(setDefaultButtons), imageName: ButtonName.cancel)
        confirmButton = UIBarButtonItem.make(target: self, action: #selector(deleteSelectedItems), imageName: ButtonName.confirm)
        deleteButton = UIBarButtonItem.make(target: self, action: #selector(setEditModeButtons), imageName: ButtonName.delete)
        makeNewMessageButton = UIBarButtonItem.make(target: self, action: #selector(showMakeNewMessageController), imageName: ButtonName.makeNewMessage)
        makeNewProxyButton = UIBarButtonItem.make(target: self, action: #selector(makeNewProxy), imageName: ButtonName.makeNewProxy)
    }

    @objc func setDefaultButtons() {
        if proxiesManager?.proxies.isEmpty ?? false {
            animate(makeNewProxyButton, loop: true)
        }
        controller?.navigationItem.leftBarButtonItem = deleteButton
        controller?.navigationItem.rightBarButtonItems = [makeNewMessageButton, makeNewProxyButton]
        itemsToDeleteManager?.itemsToDelete.removeAll()
        makeNewProxyButton.isEnabled = true
        makeNewProxyButton.customView?.isHidden = false
        tableView?.setEditing(false, animated: true)

    }

    @objc func setEditModeButtons() {
        controller?.navigationItem.leftBarButtonItem = cancelButton
        controller?.navigationItem.rightBarButtonItems = [confirmButton, makeNewProxyButton]
        makeNewProxyButton.isEnabled = false
        makeNewProxyButton.customView?.isHidden = true
        tableView?.setEditing(true, animated: true)
    }

    @objc func deleteSelectedItems() {
        guard let itemsToDelete = itemsToDeleteManager?.itemsToDelete else {
            return
        }
        if itemsToDelete.isEmpty {
            setDefaultButtons()
            return
        }
        let alert = UIAlertController(title: "Delete Proxies?", message: "Your conversations for the proxies will also be deleted.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            for (_, item) in itemsToDelete {
                guard let proxy = item as? Proxy else {
                    continue
                }
                DB.deleteProxy(proxy) { _ in }
            }
            self?.setDefaultButtons()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        controller?.present(alert, animated: true)
    }

    @objc func makeNewProxy() {
        guard
            let uid = uid,
            let proxyCount = proxiesManager?.proxies.count else {
                return
        }
        animate(makeNewProxyButton)
        makeNewProxyButton.isEnabled = false
        DB.makeProxy(uid: uid, currentProxyCount: proxyCount) { [weak self] (result) in
            switch result {
            case .failure(let error):
                self?.controller?.showAlert(title: "Error Creating Proxy", message: error.description)
            case .success:
                guard let controller = self?.controller as? ProxiesViewController else {
                    return
                }
                controller.scrollToTop()
            }
            self?.makeNewProxyButton.isEnabled = true
        }
    }

    @objc func showMakeNewMessageController() {
        guard
            let uid = uid,
            let controller = controller,
            let proxiesManager = proxiesManager,
            let proxyKeysManager = proxyKeysManager else {
                return
        }
        animate(makeNewMessageButton)
        makeNewMessageButton.isEnabled = false
        delegate?.showMakeNewMessageController(sender: nil, uid: uid, proxiesManager: proxiesManager, proxyKeysManager: proxyKeysManager, controller: controller)
        makeNewMessageButton.isEnabled = true
    }
}
