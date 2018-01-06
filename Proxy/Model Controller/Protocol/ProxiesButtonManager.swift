import UIKit
import ViewGlower

class ProxiesButtonManager: ButtonManaging {
    let viewGlower = ViewGlower()
    var cancelButton = UIBarButtonItem()
    var confirmButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    var makeNewMessageButton = UIBarButtonItem()
    var makeNewProxyButton = UIBarButtonItem()
    private var uid = ""
    private weak var controller: ProxiesViewController?
    private weak var itemsToDeleteManager: ItemsToDeleteManaging?
    private weak var navigationItem: UINavigationItem?
    private weak var proxiesManager: ProxiesManaging?
    private weak var tableView: UITableView?

    // todo: use proxiesvc delegate
    func load(uid: String,
              controller: ProxiesViewController,
              itemsToDeleteManager: ItemsToDeleteManaging,
              proxiesManager: ProxiesManaging,
              tableView: UITableView) {
        self.uid = uid
        self.controller = controller
        self.itemsToDeleteManager = itemsToDeleteManager
        self.proxiesManager = proxiesManager
        self.navigationItem = controller.navigationItem
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
        tableView?.setEditing(false, animated: true)
        itemsToDeleteManager?.itemsToDelete.removeAll()
        navigationItem?.leftBarButtonItem = deleteButton
        navigationItem?.rightBarButtonItems = [makeNewMessageButton, makeNewProxyButton]
        makeNewProxyButton.isEnabled = true
        makeNewProxyButton.customView?.isHidden = false
        if proxiesManager?.proxies.isEmpty ?? false {
            animate(makeNewProxyButton, loop: true)
        }
    }

    @objc func setEditModeButtons() {
        tableView?.setEditing(true, animated: true)
        navigationItem?.leftBarButtonItem = cancelButton
        navigationItem?.rightBarButtonItems = [confirmButton, makeNewProxyButton]
        makeNewProxyButton.isEnabled = false
        makeNewProxyButton.customView?.isHidden = true
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
        guard let proxyCount = proxiesManager?.proxies.count else {
            return
        }
        makeNewProxyButton.isEnabled = false
        animate(makeNewProxyButton)
        DB.makeProxy(uid: uid, currentProxyCount: proxyCount) { (result) in
            switch result {
            case .failure(let error):
                self.controller?.showAlert(title: "Error Creating Proxy", message: error.description)
            case .success:
                self.controller?.scrollToTop()
            }
            self.makeNewProxyButton.isEnabled = true
        }
    }

    @objc func showMakeNewMessageController() {
        defer {
            makeNewMessageButton.isEnabled = true
        }
        makeNewMessageButton.isEnabled = false
        animate(makeNewMessageButton)
        guard let controller = controller,
            let proxiesManager = proxiesManager else {
                return
        }
        controller.showMakeNewMessageController(sender: nil, uid: uid, manager: proxiesManager, controller: controller)
    }
}
