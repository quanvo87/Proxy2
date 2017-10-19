import UIKit

class ProxiesButtonManager: ButtonManaging {
    var cancelButton = UIBarButtonItem()
    var confirmButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    var makeNewMessageButton = UIBarButtonItem()
    var makeNewProxyButton = UIBarButtonItem()
    var itemsToDeleteManager: ItemsToDeleteManaging?
    weak var navigationItem: UINavigationItem?
    weak var tableView: UITableView?
    private var uid = String()
    private weak var controller: ProxiesTableViewController?
    private weak var proxiesManager: ProxiesManager?

    func load(controller: ProxiesTableViewController, itemsToDeleteManager: ItemsToDeleteManaging, proxiesManager: ProxiesManager, uid: String) {
        self.controller = controller
        self.itemsToDeleteManager = itemsToDeleteManager
        self.proxiesManager = proxiesManager
        self.uid = uid
        navigationItem = controller.navigationItem
        tableView = controller.tableView
        makeButtons()
        setDefaultButtons()
    }

    func _deleteSelectedItems() {
        if itemsToDeleteManager?.itemsToDelete.isEmpty ?? true {
            toggleEditMode()
            return
        }
        let alert = UIAlertController(title: "Delete Proxies?", message: "You will not be able to view their conversations anymore.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            guard let controller = self.controller else { return }
            self.disableButtons()
            self.proxiesManager?.stopObserving()
            let key = AsyncWorkGroupKey()
            for (_, item) in self.itemsToDeleteManager?.itemsToDelete ?? [:] {
                guard let proxy = item as? Proxy else { return }
                key.startWork()
                DBProxy.deleteProxy(proxy) { _ in
                    key.finishWork()
                }
            }
            self.itemsToDeleteManager?.itemsToDelete.removeAll()
            self.setDefaultButtons()
            self.controller?.tableView.setEditing(false, animated: true)
            key.notify {
                key.finishWorkGroup()
                self.enableButtons()
                self.proxiesManager?.load(uid: self.uid, tableView: controller.tableView)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        controller?.present(alert, animated: true)
    }

    func _makeNewProxy() {
        controller?.navigationItem.toggleRightBarButtonItem(atIndex: 1)
        DBProxy.makeProxy(forUser: uid) { (result) in
            self.controller?.navigationItem.toggleRightBarButtonItem(atIndex: 1)
            switch result {
            case .failure(let error):
                self.controller?.showAlert("Error Creating Proxy", message: error.description)
            case .success:
                self.controller?.scrollToTop()
            }
        }
    }

    func _showMakeNewMessageController() {
        controller?.showMakeNewMessageController()
    }
    
    func _toggleEditMode() {
        toggleEditMode()
    }
}
