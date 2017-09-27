import UIKit

class ProxiesButtonManager: ButtonManaging {
    let itemsToDeleteManager: ItemsToDeleteManaging
    
    var cancelButton = UIBarButtonItem()
    var confirmButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    var makeNewMessageButton = UIBarButtonItem()
    var makeNewProxyButton = UIBarButtonItem()
    
    weak var controller: ProxiesTableViewController?
    weak var navigationItem: UINavigationItem?
    weak var tableView: UITableView?

    init(_ controller: ProxiesTableViewController) {
        self.controller = controller
        itemsToDeleteManager = ItemsToDeleteManager()
        navigationItem = controller.navigationItem
        tableView = controller.tableView
        makeButtons()
        setDefaultButtons()
    }

    func _deleteSelectedItems() {
        if itemsToDeleteManager.itemsToDelete.isEmpty {
            toggleEditMode()
            return
        }
        let alert = UIAlertController(title: "Delete Proxies?", message: "You will not be able to view their conversations anymore.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            guard let controller = self.controller else { return }
            self.disableButtons()
            controller.proxiesManager.observer.stopObserving()
            let key = AsyncWorkGroupKey()
            for (_, item) in self.itemsToDeleteManager.itemsToDelete {
                guard let proxy = item as? Proxy else { return }
                key.startWork()
                DBProxy.deleteProxy(proxy) { _ in
                    key.finishWork()
                }
            }
            self.itemsToDeleteManager.itemsToDelete.removeAll()
            self.setDefaultButtons()
            self.controller?.tableView.setEditing(false, animated: true)
            key.notify {
                key.finishWorkGroup()
                self.enableButtons()
                controller.proxiesManager.observer.observe(controller.proxiesManager)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        controller?.present(alert, animated: true)
    }

    func _goToMakeNewMessageVC() {
        controller?.goToMakeNewMessageVC()
    }

    func _makeNewProxy() {
        controller?.navigationItem.toggleRightBarButtonItem(atIndex: 1)
        DBProxy.makeProxy { (result) in
            self.controller?.navigationItem.toggleRightBarButtonItem(atIndex: 1)
            switch result {
            case .failure(let error):
                self.controller?.showAlert("Error Creating Proxy", message: error.description)
            case .success:
                self.controller?.scrollToTop()
            }
        }
    }

    func _toggleEditMode() {
        toggleEditMode()
    }
}
