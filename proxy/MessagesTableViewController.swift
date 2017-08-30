class MessagesTableViewController: UITableViewController {
    let authObserver = AuthObserver()
    let dataSource = MessagesTableViewDataSource()
    var navigationItemManager = NavigationItemManager()
    let unreadCountObserver = UnreadCountObserver()

    var convo: Convo?
    var shouldGoToNewConvo = false

    override func viewDidLoad() {
        super.viewDidLoad()

        authObserver.observe(self)

        edgesForExtendedLayout = .all

        navigationItem.title = "Messages"

        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.dataSource = dataSource
        tableView.rowHeight = 80
        tableView.separatorStyle = .none
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if  shouldGoToNewConvo,
            let convo = convo,
            let convoVC = storyboard?.instantiateViewController(withIdentifier: Identifier.ConvoViewController) as? ConvoViewController {
            convoVC.convo = convo
            self.convo = nil
            shouldGoToNewConvo = false
            navigationController?.pushViewController(convoVC, animated: true)
        }
    }
}

extension MessagesTableViewController {
    var convos: [Convo] {
        return dataSource.convosObserver.getConvos()
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let convo = convos[safe: indexPath.row] else {
            return
        }
        if tableView.isEditing {
            navigationItemManager.itemsToDelete.append(convo)
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            if let convoVC = storyboard?.instantiateViewController(withIdentifier: Identifier.ConvoViewController) as? ConvoViewController {
                convoVC.convo = convo
                navigationController?.pushViewController(convoVC, animated: true)
            }
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let convo = convos[safe: indexPath.row] else {
            return
        }
        if let index = convos.index(where: { $0 == convo }) {
            navigationItemManager.itemsToDelete.remove(at: index)
        }
    }
}

extension MessagesTableViewController: AuthObserverDelegate {
    func logIn() {
        dataSource.load(tableView)
        navigationItemManager.makeButtons(self)
        setDefaultButtons()
        tabBarController?.tabBar.items?.setupForTabBar()
        unreadCountObserver.observe(self)
    }

    func logOut() {
        if  let loginVC = self.storyboard?.instantiateViewController(withIdentifier: Identifier.LoginViewController) as? LoginViewController,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.window?.rootViewController = loginVC
        }
    }
}

extension MessagesTableViewController: MakeNewMessageViewControllerDelegate {
    func prepareToShowNewConvo(_ convo: Convo) {
        self.convo = convo
        shouldGoToNewConvo = true
    }
}

extension MessagesTableViewController: NavigationItemManagerDelegate {
    func setDefaultButtons() {
        navigationItem.leftBarButtonItem = navigationItemManager.deleteButton
        navigationItem.rightBarButtonItems = [navigationItemManager.newMessageButton,
                                              navigationItemManager.newProxyButton]
    }

    func setEditModeButtons() {
        navigationItem.leftBarButtonItem = navigationItemManager.cancelButton
        navigationItem.rightBarButtonItems = [navigationItemManager.confirmButton]
    }

    func toggleEditMode() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        if tableView.isEditing {
            setEditModeButtons()
        } else {
            setDefaultButtons()
            navigationItemManager.itemsToDelete = []
        }
    }

    func deleteSelectedItems() {
        if navigationItemManager.itemsToDelete.isEmpty {
            toggleEditMode()
            return
        }
        let alert = UIAlertController(title: "Leave Conversations?", message: "This will hide them until you receive another message in them.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Leave", style: .destructive) { _ in
            var index = 0
            for item in self.navigationItemManager.itemsToDelete {
                if let convo = item as? Convo {
                    DBConvo.leaveConvo(convo) { _ in }
                }
                self.navigationItemManager.itemsToDelete.remove(at: index)
                index += 1
            }
            self.tableView.setEditing(false, animated: true)
            self.setDefaultButtons()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func makeNewProxy() {
        toggleRightBarButtonItem(atIndex: 1)
        DBProxy.makeProxy { (result) in
            self.toggleRightBarButtonItem(atIndex: 1)
            switch result {
            case .failure(let error):
                self.showAlert("Error Creating Proxy", message: error.description)
            case .success:
                NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.madeNewProxyFromHomeTab), object: nil)
                self.tabBarController?.selectedIndex = 1
            }
        }
    }

    func goToMakeNewMessageVC() {
        if let makeNewMessageVC = self.storyboard?.instantiateViewController(withIdentifier: Identifier.NewMessageViewController) as? MakeNewMessageViewController {
            makeNewMessageVC.delegate = self
            let navigationController = UINavigationController(rootViewController: makeNewMessageVC)
            present(navigationController, animated: true)
        }
    }

    func toggleRightBarButtonItem(atIndex index: Int) {
        if let item = navigationItem.rightBarButtonItems?[safe: index] {
            item.isEnabled = !item.isEnabled
        }
    }
}

extension MessagesTableViewController: UnreadObserverDelegate {
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
        self[0].image = UIImage(named: "Assets/App Icons/Messages")?.resize(toNewSize: UISettings.navBarButtonCGSize, isAspectRatio: true)
        self[1].image = UIImage(named: "Assets/App Icons/Proxy")?.resize(toNewSize: UISettings.navBarButtonCGSize, isAspectRatio: true)
        self[2].image = UIImage(named: "Assets/App Icons/Me")?.resize(toNewSize: UISettings.navBarButtonCGSize, isAspectRatio: true)
    }
}
