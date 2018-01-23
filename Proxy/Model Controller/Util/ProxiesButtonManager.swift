import UIKit

class ProxiesButtonManager {
    var cancelButton = UIBarButtonItem()
    var confirmButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    var makeNewMessageButton = UIBarButtonItem()
    var makeNewProxyButton = UIBarButtonItem()
    private let uid: String
    private weak var controller: UIViewController?
    private weak var itemsToDeleteManager: ItemsToDeleteManaging?
    private weak var newConvoManager: NewConvoManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var tableView: UITableView?

    init(uid: String,
         controller: UIViewController?,
         itemsToDeleteManager: ItemsToDeleteManaging?,
         newConvoManager: NewConvoManaging?,
         proxiesManager: ProxiesManaging?,
         tableView: UITableView?) {
        self.uid = uid
        self.controller = controller
        self.itemsToDeleteManager = itemsToDeleteManager
        self.newConvoManager = newConvoManager
        self.proxiesManager = proxiesManager
        self.tableView = tableView
        cancelButton = UIBarButtonItem.make(target: self, action: #selector(setDefaultButtons), imageName: ButtonName.cancel)
        confirmButton = UIBarButtonItem.make(target: self, action: #selector(deleteSelectedItems), imageName: ButtonName.confirm)
        deleteButton = UIBarButtonItem.make(target: self, action: #selector(setEditModeButtons), imageName: ButtonName.delete)
        makeNewMessageButton = UIBarButtonItem.make(target: self, action: #selector(showMakeNewMessageController), imageName: ButtonName.makeNewMessage)
        makeNewProxyButton = UIBarButtonItem.make(target: self, action: #selector(makeNewProxy), imageName: ButtonName.makeNewProxy)
        setDefaultButtons()
    }
}

extension ProxiesButtonManager: ButtonManaging {
    func animateButton() {
        makeNewProxyButton.animate(loop: true)
    }

    func stopAnimatingButton() {
        makeNewProxyButton.stopAnimating()
    }
}

private extension ProxiesButtonManager {
    @objc func setDefaultButtons() {
        if proxiesManager?.proxies.isEmpty ?? false {
            makeNewProxyButton.animate(loop: true)
        }
        controller?.navigationItem.leftBarButtonItem = deleteButton
        controller?.navigationItem.rightBarButtonItems = [makeNewMessageButton, makeNewProxyButton]
        itemsToDeleteManager?.itemsToDelete.removeAll()
        makeNewProxyButton.customView?.isHidden = false
        makeNewProxyButton.isEnabled = true
        tableView?.setEditing(false, animated: true)
    }

    @objc func setEditModeButtons() {
        controller?.navigationItem.leftBarButtonItem = cancelButton
        controller?.navigationItem.rightBarButtonItems = [confirmButton, makeNewProxyButton]
        makeNewProxyButton.customView?.isHidden = true
        makeNewProxyButton.isEnabled = false
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
//                Database.deleteProxy(proxy) { _ in }
            }
            self?.itemsToDeleteManager?.itemsToDelete.removeAll()
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
        makeNewProxyButton.animate()
//        Database.makeProxy(uid: uid, currentProxyCount: proxyCount) { [weak self] (result) in
//            switch result {
//            case .failure(let error):
//                self?.controller?.showAlert(title: "Error Creating Proxy", message: error.description)
//            case .success:
//                guard let controller = self?.controller as? ProxiesViewController else {
//                    return
//                }
//                controller.scrollToTop()
//            }
//            self?.makeNewProxyButton.isEnabled = true
//        }
    }

    @objc func showMakeNewMessageController() {
        makeNewMessageButton.isEnabled = false
        makeNewMessageButton.animate()
//        newConvoManager?.showMakeNewMessageController(sender: nil, uid: uid, manager: proxiesManager, controller: controller)
        makeNewMessageButton.isEnabled = true
    }
}
