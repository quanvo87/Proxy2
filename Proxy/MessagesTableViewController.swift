import UIKit

class MessagesTableViewController: UITableViewController, ButtonManaging {
    private let authObserver = AuthObserver()
    private let dataSource = MessagesTableViewDataSource()
    private let unreadCountObserver = UnreadCountObserver()
    private var newConvo: Convo?
    var buttons = Buttons()
    var itemsToDelete = [String : Any]()

    override func viewDidLoad() {
        super.viewDidLoad()

        authObserver.observe(self)

        edgesForExtendedLayout = .all

        navigationItem.title = "Messages"

        tabBarController?.tabBar.items?.setupForTabBar()

        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.rowHeight = 80
        tableView.separatorStyle = .none
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        if let newConvo = newConvo {
            goToConvoVC(newConvo)
        }
    }
}

extension MessagesTableViewController {
    var convos: [Convo] {
        return dataSource.convos
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let convo = convos[safe: indexPath.row] else {
            return
        }
        if tableView.isEditing {
            itemsToDelete[convo.key] = convo
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            goToConvoVC(convo)
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let convo = convos[safe: indexPath.row] else {
            return
        }
        itemsToDelete.removeValue(forKey: convo.key)
    }
}

extension MessagesTableViewController: AuthObserverDelegate {
    func logIn() {
        dataSource.observe(tableView)
        makeButtons(self)
        setDefaultButtons()
        DispatchQueue.global().async {
            DBProxy.fixConvoCounts { _ in }
            self.unreadCountObserver.observe(delegate: self)
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

extension MessagesTableViewController: ButtonManagerDelegate {
    func deleteSelectedItems() {
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

    func goToMakeNewMessageVC() {
        guard let makeNewMessageVC = storyboard?.instantiateViewController(withIdentifier: Identifier.makeNewMessageViewController) as? MakeNewMessageViewController else { return }
        makeNewMessageVC.setDelegate(to: self)
        let navigationController = UINavigationController(rootViewController: makeNewMessageVC)
        present(navigationController, animated: true)
    }

    func makeNewProxy() {
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

    func setDefaultButtons() {
        navigationItem.leftBarButtonItem = buttons.deleteButton
        navigationItem.rightBarButtonItems = [buttons.makeNewMessageButton, buttons.makeNewProxyButton]
    }

    func setEditModeButtons() {
        navigationItem.leftBarButtonItem = buttons.cancelButton
        navigationItem.rightBarButtonItems = [buttons.confirmButton]
    }

    func toggleEditMode() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        if tableView.isEditing {
            setEditModeButtons()
        } else {
            setDefaultButtons()
            itemsToDelete.removeAll()
        }
    }
}

extension MessagesTableViewController: MakeNewMessageDelegate {
    func setNewConvo(to convo: Convo) {
        newConvo = convo
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
