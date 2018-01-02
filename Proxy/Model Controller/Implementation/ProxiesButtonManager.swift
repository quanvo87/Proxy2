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
    private var container: DependencyContaining = DependencyContainer.container
    private weak var controller: ProxiesViewController?

    func load(uid: String, itemsToDeleteManager: ItemsToDeleteManaging, tableView: UITableView, proxiesViewController: ProxiesViewController, container: DependencyContaining) {
        self.uid = uid
        self.itemsToDeleteManager = itemsToDeleteManager
        self.tableView = tableView
        self.controller = proxiesViewController
        self.container = container
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
            self.container.proxiesManager.stopObserving()
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
                self.container.proxiesManager.observe()
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        controller?.present(alert, animated: true)
    }

    func _makeNewProxy() {
        guard let uid = uid  else {
            return
        }
        controller?.navigationItem.disableRightBarButtonItem(atIndex: 1)
        DB.makeProxy(forUser: uid, currentProxyCount: container.proxiesManager.proxies.count) { (result) in
            self.controller?.navigationItem.enableRightBarButtonItem(atIndex: 1)
            switch result {
            case .failure(let error):
                self.controller?.showAlert("Error Creating Proxy", message: error.description)
            case .success:
                self.controller?.scrollToTop()
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
        guard let uid = uid, let controller = controller else {
            return
        }
        controller.showMakeNewMessageController(uid: uid, sender: nil, controller: controller, container: container)
    }
}
