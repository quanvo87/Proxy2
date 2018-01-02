import GroupWork
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

    private var uid: String?
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
        guard let itemsToDeleteManager = itemsToDeleteManager else {
            return
        }
        if itemsToDeleteManager.itemsToDelete.isEmpty {
            setDefaultButtons()
            return
        }
        let alert = UIAlertController(title: "Delete Proxies?", message: "Your conversations for the proxies will also be deleted.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.disableButtons()
            self.proxiesManager?.observer.stopObserving()
            let key = GroupWork()
            for (_, item) in itemsToDeleteManager.itemsToDelete {
                guard let proxy = item as? Proxy else {
                    return
                }
                key.start()
                DB.deleteProxy(proxy) { _ in
                    key.finish(withResult: true)
                }
            }
            self.setDefaultButtons()
            key.allDone {
                self.enableButtons()
                self.proxiesManager?.observer.observe()
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        proxiesViewController?.present(alert, animated: true)
    }

    func _makeNewProxy() {
        guard let uid = uid, let proxyCount = proxiesManager?.proxies.count else {
            return
        }
        proxiesViewController?.navigationItem.disableRightBarButtonItem(atIndex: 1)
        DB.makeProxy(forUser: uid, currentProxyCount: proxyCount) { (result) in
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
        guard let uid = uid else {
            return
        }
        proxiesViewController?.showMakeNewMessageController(uid: uid, proxiesManager: proxiesManager, sender: nil, controller: proxiesViewController)
    }
}
