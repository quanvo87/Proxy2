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
    private weak var proxiesManager: ProxiesManaging?
    private weak var controller: UIViewController?

    func load(uid: String, makeNewMessageDelegate: MakeNewMessageDelegate, proxiesManager: ProxiesManaging, controller: UIViewController) {
        self.uid = uid
        self.makeNewMessageDelegate = makeNewMessageDelegate
        self.proxiesManager = proxiesManager
        self.controller = controller
        navigationItem = controller.navigationItem
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
        guard let uid = uid, let proxyCount = proxiesManager?.proxies.count else {
            return
        }
        navigationItem?.disableRightBarButtonItem(atIndex: 1)
        DB.makeProxy(forUser: uid, currentProxyCount: proxyCount) { (result) in
            self.navigationItem?.enableRightBarButtonItem(atIndex: 1)
            switch result {
            case .failure(let error):
                self.controller?.showAlert("Error Creating Proxy", message: error.description)
                self.controller?.tabBarController?.selectedIndex = 1
            case .success:
                guard
                    let proxiesNavigationController = self.controller?.tabBarController?.viewControllers?[safe: 1] as? UINavigationController,
                    let proxiesViewController = proxiesNavigationController.viewControllers[safe: 0] as? ProxiesViewController else {
                        return
                }
                proxiesViewController.scrollToTop()
                self.controller?.tabBarController?.selectedIndex = 1
            }
        }
    }

    func _setDefaultButtons() {}

    func _setEditModeButtons() {}

    func _showMakeNewMessageController() {
        guard let uid = uid else {
            return
        }
        makeNewMessageDelegate?.showMakeNewMessageController(uid: uid, proxiesManager: proxiesManager, sender: nil, controller: controller)
    }
}
