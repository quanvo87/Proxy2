import UIKit

class MessagesButtonManager: ButtonManaging {
    private var uid = ""
    private weak var makeNewMessageDelegate: MakeNewMessageDelegate?
    private weak var viewController: UIViewController?
    var itemsToDeleteManager: ItemsToDeleteManaging?
    var cancelButton = UIBarButtonItem()
    var confirmButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    var makeNewMessageButton = UIBarButtonItem()
    var makeNewProxyButton = UIBarButtonItem()
    weak var navigationItem: UINavigationItem?
    weak var tableView: UITableView?

    func load(itemsToDeleteManager: ItemsToDeleteManaging, makeNewMessageDelegate: MakeNewMessageDelegate, uid: String, viewController: UIViewController, tableView: UITableView) {
        self.itemsToDeleteManager = itemsToDeleteManager
        self.makeNewMessageDelegate = makeNewMessageDelegate
        self.uid = uid
        self.viewController = viewController
        self.tableView = tableView
        navigationItem = viewController.navigationItem
        makeButtons()
        setDefaultButtons()
    }

    func _deleteSelectedItems() {
        if itemsToDeleteManager?.itemsToDelete.isEmpty ?? true {
            setDefaultButtons()
            return
        }
        let alert = UIAlertController(title: "Leave Conversations?", message: "This will not delete the conversations.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Leave", style: .destructive) { _ in
            for (_, item) in self.itemsToDeleteManager?.itemsToDelete ?? [:] {
                guard let convo = item as? Convo else {
                    return
                }
                DBConvo.leaveConvo(convo) { _ in }
            }
            self.setDefaultButtons()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        viewController?.present(alert, animated: true)
    }

    func _makeNewProxy() {
        navigationItem?.disableRightBarButtonItem(atIndex: 1)
        DBProxy.makeProxy(forUser: uid) { (result) in
            self.navigationItem?.enableRightBarButtonItem(atIndex: 1)
            switch result {
            case .failure(let error):
                self.viewController?.showAlert("Error Creating Proxy", message: error.description)
                self.viewController?.tabBarController?.selectedIndex = 1
            case .success:
                guard
                    let proxiesNavigationController = self.viewController?.tabBarController?.viewControllers?[safe: 1] as? UINavigationController,
                    let proxiesViewController = proxiesNavigationController.viewControllers[safe: 0] as? ProxiesViewController else {
                        return
                }
                proxiesViewController.scrollToTop()
                self.viewController?.tabBarController?.selectedIndex = 1
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
        makeNewMessageDelegate?.showMakeNewMessageController(sender: nil, uid: uid, viewController: viewController)
    }
}
