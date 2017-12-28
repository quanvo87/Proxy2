import UIKit

class ConvosButtonManager: ButtonManaging {
    var itemsToDeleteManager: ItemsToDeleteManaging?
    var cancelButton = UIBarButtonItem()
    var confirmButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    var makeNewMessageButton = UIBarButtonItem()
    var makeNewProxyButton = UIBarButtonItem()
    weak var navigationItem: UINavigationItem?
    weak var tableView: UITableView?

    private var uid: String?
    private weak var makeNewMessageDelegate: MakeNewMessageDelegate?
    private weak var viewController: UIViewController?

    func load(uid: String, makeNewMessageDelegate: MakeNewMessageDelegate, viewController: UIViewController) {
        self.uid = uid
        self.makeNewMessageDelegate = makeNewMessageDelegate
        self.viewController = viewController
        navigationItem = viewController.navigationItem
        makeButtons()
        setDefaultButtons()
    }

    func makeButtons() {
        makeNewMessageButton = UIBarButtonItem.make(target: self, action: #selector(_showMakeNewMessageController), imageName: ButtonName.makeNewMessage)
        makeNewProxyButton = UIBarButtonItem.make(target: self, action: #selector(_makeNewProxy), imageName: ButtonName.makeNewProxy)
    }

    func setDefaultButtons() {
        navigationItem?.rightBarButtonItems = [makeNewMessageButton, makeNewProxyButton]
    }

    func _deleteSelectedItems() {}

    func _makeNewProxy() {
        guard let uid = uid else {
            return
        }
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

    func _setDefaultButtons() {}

    func _setEditModeButtons() {}

    func _showMakeNewMessageController() {
        guard let uid = uid else {
            return
        }
        makeNewMessageDelegate?.showMakeNewMessageController(uid: uid, sender: nil, controller: viewController)
    }
}
