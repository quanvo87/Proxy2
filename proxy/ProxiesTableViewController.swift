class ProxiesTableViewController: UITableViewController {
    private var buttonManager = ButtonManager()
    private let dataSource = ProxiesTableViewDataSource()
    private var newConvo: Convo?
    private let unreadCountObserver = UnreadCountObserver()

    override func viewDidLoad() {
        super.viewDidLoad()

        buttonManager.makeButtons(self)

        dataSource.observe(tableView)

        navigationItem.title = "Proxies"

        setDefaultButtons()
        
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.dataSource = dataSource
        tableView.rowHeight = 60
        tableView.separatorStyle = .none

        unreadCountObserver.observe(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        goToNewConvo()
        scrollToTop()
    }

    func goToNewConvo() {
        guard
            let newConvo = newConvo,
            let convoVC = storyboard?.instantiateViewController(withIdentifier: Identifier.ConvoViewController) as? ConvoViewController else {
                return
        }
        convoVC.convo = newConvo
        self.newConvo = nil
        navigationController?.pushViewController(convoVC, animated: true)
    }

    func scrollToTop() {
        if tableView.numberOfRows(inSection: 0) > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
}

extension ProxiesTableViewController {
    var proxies: [Proxy] {
        return dataSource.proxies
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let proxy = proxies[safe: indexPath.row] else {
            return
        }
        if tableView.isEditing {
            buttonManager.itemsToDeleteSet(value: proxy, forKey: proxy.key)
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            goToProxyInfoVC(proxy)
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let proxy = proxies[safe: indexPath.row] else {
            return
        }
        buttonManager.itemsToDeleteRemoveValue(forKey: proxy.key)
    }

    func goToProxyInfoVC(_ proxy: Proxy) {
        if let proxyInfoVC = storyboard?.instantiateViewController(withIdentifier: Identifier.ProxyInfoTableViewController) as? ProxyInfoTableViewController {
            proxyInfoVC.setProxy(proxy)
            navigationController?.pushViewController(proxyInfoVC, animated: true)
        }
    }
}

extension ProxiesTableViewController: ButtonManagerDelegate {
    func deleteSelectedItems() {
        if buttonManager.itemsToDelete.isEmpty {
            toggleEditMode()
            return
        }
        let alert = UIAlertController(title: "Delete Proxies?", message: "You will not be able to view their conversations anymore.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.buttonManager.disableButtons()
            self.dataSource.stopObserving()
            let key = AsyncWorkGroupKey()
            for (_, item) in self.buttonManager.itemsToDelete {
                if let proxy = item as? Proxy {
                    key.startWork()
                    DBProxy.deleteProxy(proxy) { _ in
                        key.finishWork()
                    }
                }
            }
            self.buttonManager.itemsToDeleteRemoveAll()
            self.setDefaultButtons()
            self.tableView.setEditing(false, animated: true)
            key.notify {
                key.finishWorkGroup()
                self.buttonManager.enableButtons()
                self.dataSource.observe(self.tableView)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func goToMakeNewMessageVC() {
        if let makeNewMessageVC = self.storyboard?.instantiateViewController(withIdentifier: Identifier.NewMessageViewController) as? MakeNewMessageViewController {
            makeNewMessageVC.setDelegate(to: self)
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
                self.scrollToTop()
            }
        }
    }

    func setDefaultButtons() {
        navigationItem.leftBarButtonItem = buttonManager.deleteButton
        navigationItem.rightBarButtonItems = [buttonManager.makeNewMessageButton, buttonManager.makeNewProxyButton]
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
            buttonManager.itemsToDeleteRemoveAll()
        }
    }
}

extension ProxiesTableViewController: MakeNewMessageDelegate {
    func setNewConvo(to convo: Convo) {
        newConvo = convo
    }
}

extension ProxiesTableViewController: UnreadObserverDelegate {
    func setUnreadCount(to unreadCount: Int?) {
        if let unreadCount = unreadCount {
            navigationItem.title = "Proxies" + unreadCount.asLabelWithParens
        } else {
            navigationItem.title = "Proxies"
        }
    }
}
