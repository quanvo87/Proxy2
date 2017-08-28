class MessagesTableViewController: UITableViewController {
    let authObserver = AuthObserver()
    let dataSource = MessagesTableViewDataSource()
    var navigationItemManager = NavigationItemManager()
    let unreadObserver = UnreadObserver()

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
            let convoVC = storyboard?.instantiateViewController(withIdentifier: Identifier.ConvoViewController) as? ConvoViewController,
            let navigationController = navigationController
        {
            shouldGoToNewConvo = false
            self.convo = nil
            convoVC.convo = convo
            navigationController.pushViewController(convoVC, animated: true)
        }
    }

    var convos: [Convo] {
        return dataSource.convosObserver.convos
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let convo = convos[indexPath.row]
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
        let convo = convos[indexPath.row]
        if let index = convos.index(where: { $0.key == convo.key }) {
            navigationItemManager.itemsToDelete.remove(at: index)
        }
    }
}

extension MessagesTableViewController: AuthObserverDelegate {
    func logIn() {
        dataSource.load(self)
        DBStorage.loadProxyInfo()
        navigationItemManager.makeButtons(self)
        setDefaultButtons()
        tabBarController?.tabBar.items?.setupForTabBar()
        unreadObserver.observe(self)
    }

    func logOut() {
        if  let loginVC = self.storyboard?.instantiateViewController(withIdentifier: Identifier.LoginViewController) as? LoginViewController,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
        {
            appDelegate.window?.rootViewController = loginVC
        }
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
            let key = AsyncWorkGroupKey()
            var index = 0
            for item in self.navigationItemManager.itemsToDelete {
                if let convo = item as? Convo {
                    key.startWork()
                    DBConvo.leaveConvo(convo) { (success) in
                        key.finishWork(withResult: success)
                    }
                }
                self.navigationItemManager.itemsToDelete.remove(at: index)
                index += 1
            }
            key.notify {
                if !key.workResult {
                    self.showAlert("Error Leaving Convos", message: "There was an error leaving some of your convos.")
                }
                key.finishWorkGroup()
            }
            self.tableView.setEditing(false, animated: true)
            self.setDefaultButtons()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func createNewProxy() {
        navigationItem.rightBarButtonItems?[1].isEnabled = false
        DBProxy.makeProxy { (result) in
            switch result {
            case .failure(let error):
                self.showAlert("Error Creating Proxy", message: error.description)
            case .success:
                NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.CreatedNewProxyFromHomeTab), object: nil)
                self.tabBarController?.selectedIndex = 1
            }
        }
    }

    func createNewMessage() {
        if let dest = self.storyboard?.instantiateViewController(withIdentifier: Identifier.NewMessageViewController) as? NewMessageViewController {
            dest.newMessageViewControllerDelegate = self
            navigationController?.pushViewController(dest, animated: true)
        }
    }
}

extension MessagesTableViewController: NewMessageViewControllerDelegate {
    func setupForNewConvo(_ convo: Convo) {
        self.convo = convo
        shouldGoToNewConvo = true
    }
}

extension MessagesTableViewController: UnreadObserverDelegate {
    func setUnread(_ unread: Int?) {
        if let unread = unread {
            self.navigationItem.title = "Messages" + unread.asLabelWithParens
            self.tabBarController?.tabBar.items?.first?.badgeValue = unread == 0 ? nil : String(unread)
        } else {
            self.navigationItem.title = "Messages"
            self.tabBarController?.tabBar.items?.first?.badgeValue = nil
        }
    }
}

private extension Array where Element: UITabBarItem {
    func setupForTabBar() {
        let size = CGSize(width: 30, height: 30)
        self[0].image = UIImage(named: "messages-tab")?.resize(toNewSize: size, isAspectRatio: true)
        self[1].image = UIImage(named: "proxies-tab")?.resize(toNewSize: size, isAspectRatio: true)
        self[2].image = UIImage(named: "me-tab")?.resize(toNewSize: size, isAspectRatio: true)
    }
}
