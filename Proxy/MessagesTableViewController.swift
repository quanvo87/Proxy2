import UIKit

class MessagesTableViewController: UITableViewController, MakeNewMessageDelegate {
    private var dataSource: MessagesTableViewDataSource?
    private var delegate: MessagesTableViewDelegate?

    private var convosManager: ConvosManager?
    private var tableViewReloader: TableViewReloader?

    private var authObserver: AuthObserver?

    private var unreadCountObserver: UnreadCountObserver?

    var itemsToDelete = [String : Any]()

    var newConvo: Convo?

    override func viewDidLoad() {
        super.viewDidLoad()
        authObserver = AuthObserver(self)

//        tableViewReloader = TableViewReloader(tableView)

        dataSource = MessagesTableViewDataSource(tableView)
        delegate = MessagesTableViewDelegate(self)

        navigationItem.title = "Messages"
        tabBarController?.tabBar.items?.setupForTabBar()
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.rowHeight = 80
        tableView.separatorStyle = .none
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let newConvo = newConvo {
            goToConvoVC(newConvo)
        }
    }
}

extension MessagesTableViewController: ItemsToDeleteManaging {
    func set(_ object: Any, forKey key: String) {
        itemsToDelete[key] = object
    }

    func remove(atKey key: String) {
        itemsToDelete.removeValue(forKey: key)
    }

    func removeAll() {
        itemsToDelete.removeAll()
    }
}

//extension MessagesTableViewController {
//    func _deleteSelectedItems() {
//        if itemsToDelete.isEmpty {
//            toggleEditMode()
//            return
//        }
//        let alert = UIAlertController(title: "Leave Conversations?", message: "This will not delete the conversation.", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "Leave", style: .destructive) { _ in
//            for (_, item) in self.itemsToDelete {
//                guard let convo = item as? Convo else { return }
//                DBConvo.leaveConvo(convo) { _ in }
//            }
//            self.itemsToDelete.removeAll()
//            self.setDefaultButtons()
//            self.tableView.setEditing(false, animated: true)
//        })
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//        present(alert, animated: true)
//    }
//
//    func _goToMakeNewMessageVC() {
//        goToMakeNewMessageVC()
//    }
//
//    func _makeNewProxy() {
//        navigationItem.toggleRightBarButtonItem(atIndex: 1)
//        DBProxy.makeProxy { (result) in
//            self.navigationItem.toggleRightBarButtonItem(atIndex: 1)
//            switch result {
//            case .failure(let error):
//                self.showAlert("Error Creating Proxy", message: error.description)
//                self.tabBarController?.selectedIndex = 1
//            case .success:
//                guard
//                    let proxiesNavigationController = self.tabBarController?.viewControllers?[safe: 1] as? UINavigationController,
//                    let proxiesViewController = proxiesNavigationController.viewControllers[safe: 0] as? ProxiesTableViewController else {
//                        return
//                }
//                proxiesViewController.scrollToTop()
//                self.tabBarController?.selectedIndex = 1
//            }
//        }
//    }
//
//    func _toggleEditMode() {
//        toggleEditMode()
//    }
//}

extension MessagesTableViewController: AuthManaging {
    func logIn() {
        convosManager = ConvosManager(convosOwner: Shared.shared.uid, delegate: tableViewReloader)
        dataSource?.manager = convosManager
        delegate?.manager = convosManager
//        makeButtons()
//        setDefaultButtons()
        unreadCountObserver = UnreadCountObserver(delegate: self)
        DispatchQueue.global().async {
            DBProxy.fixConvoCounts { _ in }
        }
    }
}

extension MessagesTableViewController: UnreadCountObserving {
    func setUnreadCount(_ count: Int?) {
        if let count = count {
            navigationItem.title = "Messages" + count.asLabelWithParens
            tabBarController?.tabBar.items?.first?.badgeValue = count == 0 ? nil : String(count)
        } else {
            navigationItem.title = "Messages"
            tabBarController?.tabBar.items?.first?.badgeValue = nil
        }
    }
}

private extension Array where Element: UITabBarItem {
    func setupForTabBar() {
        guard
            let tab0 = self[safe: 0],
            let tab1 = self[safe: 1],
            let tab2 = self[safe: 2] else {
                return
        }
        tab0.image = UIImage(named: "messages")
        tab1.image = UIImage(named: "proxies")
        tab2.image = UIImage(named: "me")
    }
}
