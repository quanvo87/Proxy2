import UIKit

class ProxiesButtonManager: ButtonManaging {
    var itemsToDeleteManager: ItemsToDeleteManaging?
    var cancelButton = UIBarButtonItem()
    var confirmButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    var makeNewMessageButton = UIBarButtonItem()
    var makeNewProxyButton = UIBarButtonItem()
    weak var navigationItem: UINavigationItem?
    weak var tableView: UITableView?

    private var uid = ""
    private weak var proxiesViewController: ProxiesViewController?
    private weak var proxiesManager: ProxiesManager?

    func load(uid: String, proxiesManager: ProxiesManager, itemsToDeleteManager: ItemsToDeleteManaging, tableView: UITableView, proxiesViewController: ProxiesViewController) {
        self.uid = uid
        self.proxiesManager = proxiesManager
        self.itemsToDeleteManager = itemsToDeleteManager
        self.tableView = tableView
        self.proxiesViewController = proxiesViewController
        navigationItem = proxiesViewController.navigationItem
        makeButtons()
        setDefaultButtons()
    }

    func _deleteSelectedItems() {
        if itemsToDeleteManager?.itemsToDelete.isEmpty ?? true {
            setDefaultButtons()
            return
        }
        let alert = UIAlertController(title: "Delete Proxies?", message: "You will not be able to view their conversations anymore.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            guard let tableView = self.tableView else {
                return
            }
            self.disableButtons()
            self.proxiesManager?.stopObserving()
            let key = AsyncWorkGroupKey()
            for (_, item) in self.itemsToDeleteManager?.itemsToDelete ?? [:] {
                guard let proxy = item as? Proxy else {
                    return
                }
                key.startWork()
                DBProxy.deleteProxy(proxy) { _ in
                    key.finishWork()
                }
            }
            self.setDefaultButtons()
            key.notify {
                key.finishWorkGroup()
                self.enableButtons()
                self.proxiesManager?.load(uid: self.uid, tableView: tableView)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        proxiesViewController?.present(alert, animated: true)
    }

    func _makeNewProxy() {
        proxiesViewController?.navigationItem.disableRightBarButtonItem(atIndex: 1)
        DBProxy.makeProxy(forUser: uid) { (result) in
            self.proxiesViewController?.navigationItem.enableRightBarButtonItem(atIndex: 1)
            switch result {
            case .failure(let error):
                self.proxiesViewController?.showAlert("Error Creating Proxy", message: error.description)
            case .success:
                self.proxiesViewController?.scrollToTop()
            }
        }
    }

    func _setDefaultButtons() {
        setDefaultButtons()
    }

    func _setEditModeButtons() {
        setEditModeButtons()
    }

    func _showMakeNewMessageController() {
        proxiesViewController?.showMakeNewMessageController(uid: uid, sender: nil, viewController: proxiesViewController)
    }
}
