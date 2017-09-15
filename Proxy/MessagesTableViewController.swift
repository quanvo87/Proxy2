import UIKit

class MessagesTableViewController: UITableViewController, ButtonManaging, ConvosObserving, MakeNewMessageDelegate {
    var cancelButton = UIBarButtonItem()
    var confirmButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    var makeNewMessageButton = UIBarButtonItem()
    var makeNewProxyButton = UIBarButtonItem()

    private let authObserver = AuthObserver()
    private var convosObserver: ConvosObserver?
    private var dataSource: MessagesTableViewDataSource?
    private var delegate: MessagesTableViewDelegate?
    private let unreadCountObserver = UnreadCountObserver()
    var convos = [Convo]()
    var itemsToDelete = [String : Any]()
    var newConvo: Convo?

    override func viewDidLoad() {
        super.viewDidLoad()
        authObserver.observe(self)
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

extension MessagesTableViewController {
    func _deleteSelectedItems() {
        if itemsToDelete.isEmpty {
            toggleEditMode()
            return
        }
        let alert = UIAlertController(title: "Leave Conversations?", message: "This will not delete the conversation.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Leave", style: .destructive) { _ in
            for (_, item) in self.itemsToDelete {
                guard let convo = item as? Convo else { return }
                DBConvo.leaveConvo(convo) { _ in }
            }
            self.itemsToDelete.removeAll()
            self.setDefaultButtons()
            self.tableView.setEditing(false, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func _goToMakeNewMessageVC() {
        goToMakeNewMessageVC()
    }

    func _makeNewProxy() {
        navigationItem.toggleRightBarButtonItem(atIndex: 1)
        DBProxy.makeProxy { (result) in
            self.navigationItem.toggleRightBarButtonItem(atIndex: 1)
            switch result {
            case .failure(let error):
                self.showAlert("Error Creating Proxy", message: error.description)
                self.tabBarController?.selectedIndex = 1
            case .success:
                guard
                    let proxiesNavigationController = self.tabBarController?.viewControllers?[safe: 1] as? UINavigationController,
                    let proxiesViewController = proxiesNavigationController.viewControllers[safe: 0] as? ProxiesTableViewController else {
                        return
                }
                proxiesViewController.scrollToTop()
                self.tabBarController?.selectedIndex = 1
            }
        }
    }

    func _toggleEditMode() {
        toggleEditMode()
    }
}

extension MessagesTableViewController: AuthObserverDelegate {
    func logIn() {
        convosObserver = ConvosObserver(owner: Shared.shared.uid, controller: self)
        convosObserver?.observe()
        dataSource = MessagesTableViewDataSource(self)
        makeButtons()
        setDefaultButtons()
        unreadCountObserver.observe(delegate: self)
        DispatchQueue.global().async {
            DBProxy.fixConvoCounts { _ in }
        }
    }

    func logOut() {
        guard
            let loginVC = storyboard?.instantiateViewController(withIdentifier: Identifier.loginViewController) as? LoginViewController,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        appDelegate.window?.rootViewController = loginVC
    }
}

extension MessagesTableViewController: UnreadCountObserverDelegate {
    func setUnreadCount(to unreadCount: Int?) {
        if let unreadCount = unreadCount {
            navigationItem.title = "Messages" + unreadCount.asLabelWithParens
            tabBarController?.tabBar.items?.first?.badgeValue = unreadCount == 0 ? nil : String(unreadCount)
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
