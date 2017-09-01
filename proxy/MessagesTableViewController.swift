class MessagesTableViewController: UITableViewController, MakeNewMessageViewControllerDelegate {
    let authObserver = AuthObserver()
    var buttonManager = ButtonManager()
    let dataSource = MessagesTableViewDataSource()
    let unreadCountObserver = UnreadCountObserver()

    var newConvo: Convo?

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
        goToNewConvo()
    }

    func goToNewConvo() {
        if  let newConvo = newConvo,
            let convoVC = storyboard?.instantiateViewController(withIdentifier: Identifier.ConvoViewController) as? ConvoViewController {
            convoVC.convo = newConvo
            self.newConvo = nil
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
            buttonManager.itemsToDelete[convo.key] = convo
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            goToConvoVC(convo)
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let convo = convos[safe: indexPath.row] else {
            return
        }
        buttonManager.itemsToDelete.removeValue(forKey: convo.key)
    }

    func goToConvoVC(_ convo: Convo) {
        if let convoVC = storyboard?.instantiateViewController(withIdentifier: Identifier.ConvoViewController) as? ConvoViewController {
            convoVC.convo = convo
            navigationController?.pushViewController(convoVC, animated: true)
        }
    }
}

extension MessagesTableViewController: AuthObserverDelegate {
    func logIn() {
        dataSource.load(tableView)
        buttonManager.makeButtons(self)
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

extension MessagesTableViewController: ButtonManagerDelegate {
    func deleteSelectedItems() {
        if buttonManager.itemsToDelete.isEmpty {
            toggleEditMode()
            return
        }
        let alert = UIAlertController(title: "Leave Conversations?", message: "This will not delete the conversation.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Leave", style: .destructive) { _ in
            self.buttonManager.disableButtons()
            self.dataSource.convosObserver.stopObserving()
            let key = AsyncWorkGroupKey()
            for (_, item) in self.buttonManager.itemsToDelete {
                if let convo = item as? Convo {
                    key.startWork()
                    DBConvo.leaveConvo(convo) { _ in
                        key.finishWork()
                    }
                }
            }
            self.buttonManager.itemsToDelete.removeAll()
            self.setDefaultButtons()
            self.tableView.setEditing(false, animated: true)
            key.notify {
                key.finishWorkGroup()
                self.buttonManager.enableButtons()
                self.dataSource.convosObserver.observe(self.tableView)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func goToMakeNewMessageVC() {
        if let makeNewMessageVC = self.storyboard?.instantiateViewController(withIdentifier: Identifier.NewMessageViewController) as? MakeNewMessageViewController {
            makeNewMessageVC.delegate = self
            let navigationController = UINavigationController(rootViewController: makeNewMessageVC)
            present(navigationController, animated: true)
        }
    }

    func makeNewProxy() {
        navigationItem.toggleRightBarButtonItem(atIndex: 1)
        DBProxy.makeProxy { (result) in
            self.navigationItem.toggleRightBarButtonItem(atIndex: 1)
            switch result {
            case .failure(let error):
                self.showAlert("Error Creating Proxy", message: error.description)
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
        navigationItem.leftBarButtonItem = buttonManager.deleteButton
        navigationItem.rightBarButtonItems = [buttonManager.newMessageButton,
                                              buttonManager.newProxyButton]
    }

    func setEditModeButtons() {
        navigationItem.leftBarButtonItem = buttonManager.cancelButton
        navigationItem.rightBarButtonItems = [buttonManager.confirmButton]
    }

    func toggleEditMode() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        if tableView.isEditing {
            setEditModeButtons()
        } else {
            setDefaultButtons()
            buttonManager.itemsToDelete.removeAll()
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
        self[0].image = UIImage(named: "Messages")
        self[1].image = UIImage(named: "My Proxies")
        self[2].image = UIImage(named: "Me")
    }
}
