import UIKit

class MessagesButtonManager: ButtonManaging {
    var cancelButton = UIBarButtonItem()
    var confirmButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    var makeNewMessageButton = UIBarButtonItem()
    var makeNewProxyButton = UIBarButtonItem()
    var itemsToDeleteManager: ItemsToDeleteManaging?
    weak var navigationItem: UINavigationItem?
    weak var tableView: UITableView?
    weak var controller: MessagesTableViewController?

    func load(_ controller: MessagesTableViewController) {
        self.controller = controller
        itemsToDeleteManager = ItemsToDeleteManager()
        navigationItem = controller.navigationItem
        tableView = controller.tableView
        makeButtons()
        setDefaultButtons()
    }
    
    func _deleteSelectedItems() {
        guard let itemsToDelete = itemsToDeleteManager?.itemsToDelete else { return }
        if itemsToDelete.isEmpty {
            toggleEditMode()
            return
        }
        let alert = UIAlertController(title: "Leave Conversations?", message: "This will not delete the conversation.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Leave", style: .destructive) { _ in
            for (_, item) in itemsToDelete {
                guard let convo = item as? Convo else { return }
                DBConvo.leaveConvo(convo) { _ in }
            }
            self.itemsToDeleteManager?.itemsToDelete.removeAll()
            self.setDefaultButtons()
            self.tableView?.setEditing(false, animated: true)
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
                self.controller?.tabBarController?.selectedIndex = 1
            case .success:
                guard
                    let proxiesNavigationController = self.controller?.tabBarController?.viewControllers?[safe: 1] as? UINavigationController,
                    let proxiesViewController = proxiesNavigationController.viewControllers[safe: 0] as? ProxiesTableViewController else {
                        return
                }
                proxiesViewController.scrollToTop()
                self.controller?.tabBarController?.selectedIndex = 1
            }
        }
    }
    
    func _toggleEditMode() {
        toggleEditMode()
    }
}
