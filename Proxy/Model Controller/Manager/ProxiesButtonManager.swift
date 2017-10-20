import UIKit

class ProxiesButtonManager: ButtonManaging {
    private var uid = String()
    var cancelButton = UIBarButtonItem()
    var confirmButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    var makeNewMessageButton = UIBarButtonItem()
    var makeNewProxyButton = UIBarButtonItem()
    var itemsToDeleteManager: ItemsToDeleteManaging?
    private weak var controller: ProxiesViewController?
    private weak var proxiesManager: ProxiesManager?
    weak var navigationItem: UINavigationItem?
    weak var tableView: UITableView?

    func load(controller: ProxiesViewController, itemsToDeleteManager: ItemsToDeleteManaging, proxiesManager: ProxiesManager, tableView: UITableView, uid: String) {
        self.controller = controller
        self.itemsToDeleteManager = itemsToDeleteManager
        self.proxiesManager = proxiesManager
        self.tableView = tableView
        self.uid = uid
        navigationItem = controller.navigationItem
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
            guard let tableView = self.tableView else { return }
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
            tableView.setEditing(false, animated: true)
            key.notify {
                key.finishWorkGroup()
                self.enableButtons()
                self.proxiesManager?.load(uid: self.uid, tableView: tableView)
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
