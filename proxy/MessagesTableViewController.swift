//
//  MessagesTableViewController.swift
//  proxy
//
//  Created by Quan Vo on 9/10/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

class MessagesTableViewController: UITableViewController {
    lazy var authObserver = AuthObserver()
    lazy var navigationItemManager = NavigationItemManager()
    lazy var dataSource = MessagesTableViewDataSource()
    lazy var unreadObserver = UnreadObserver()

    var convo: Convo?
    var shouldGoToNewConvo = false

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Messages"
        edgesForExtendedLayout = .all
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.dataSource = dataSource
        tableView.rowHeight = 80
        tableView.separatorStyle = .none

        authObserver.observe(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if  shouldGoToNewConvo,
            let convo = convo,
            let dest = storyboard?.instantiateViewController(withIdentifier: Identifiers.ConvoViewController) as? ConvoViewController,
            let navigationController = navigationController
        {
            shouldGoToNewConvo = false
            self.convo = nil
            dest.convo = convo
            navigationController.pushViewController(dest, animated: true)
        }
    }
}

extension MessagesTableViewController: AuthObserverDelegate {
    func logIn() {
        navigationItemManager.makeButtons(self)
        setDefaultButtons()
        setupTabBar()
        dataSource.load(self)
        unreadObserver.observe(self)
    }

    func logOut() {
        if  let dest = self.storyboard?.instantiateViewController(withIdentifier: Identifiers.LoginViewController) as? LoginViewController,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.window?.rootViewController = dest
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
        alert.addAction(UIAlertAction(title: "Leave", style: .destructive, handler: { (action) in
            self.tableView.setEditing(false, animated: true)
            self.setDefaultButtons()
            for item in self.navigationItemManager.itemsToDelete {
                if let convo = item as? Convo {
                    API.sharedInstance.leaveConvo(convo)
                }
            }
            self.navigationItemManager.itemsToDelete = []
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func createNewProxy() {
        navigationItem.rightBarButtonItems![1].isEnabled = false
        API.sharedInstance.createProxy { (proxy) in
            self.navigationItem.rightBarButtonItems![1].isEnabled = true
            guard proxy != nil else {
                self.showAlert("Cannot Exceed 50 Proxies", message: "Delete some proxies and try again!")
                return
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.CreatedNewProxyFromHomeTab), object: nil)
            self.tabBarController?.selectedIndex = 1
        }
    }

    func createNewMessage() {
        if let dest = self.storyboard?.instantiateViewController(withIdentifier: Identifiers.NewMessageViewController) as? NewMessageViewController {
            dest.newMessageViewControllerDelegate = self
            navigationController?.pushViewController(dest, animated: true)
        }
    }
}

extension MessagesTableViewController {
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
            let dest = storyboard!.instantiateViewController(withIdentifier: Identifiers.ConvoViewController) as! ConvoViewController
            dest.convo = convo
            navigationController!.pushViewController(dest, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let convo = convos[indexPath.row]
        if let index = convos.index(where: { $0.key == convo.key }) {
            navigationItemManager.itemsToDelete.remove(at: index)
        }
    }
}

extension MessagesTableViewController: UnreadObserverDelegate {
    func setUnread(_ unread: Int?) {
        if let unread = unread {
            self.navigationItem.title = "Messages" + unread.asUnreadLabel()
            self.tabBarController?.tabBar.items?.first?.badgeValue = unread == 0 ? nil : String(unread)
        } else {
            self.navigationItem.title = "Messages"
            self.tabBarController?.tabBar.items?.first?.badgeValue = nil
        }
    }
}

// TODO: - revisit logic, prob don't need this? just pop new message vc after pushing convo
extension MessagesTableViewController: NewMessageViewControllerDelegate {
    func goToNewConvo(_ convo: Convo) {
        self.convo = convo
        shouldGoToNewConvo = true
    }
}

extension MessagesTableViewController {
    func setupTabBar() {
        guard let items = tabBarController?.tabBar.items else {
            return
        }
        let size = CGSize(width: 30, height: 30)
        let isAspectRatio = true
        items[0].image = UIImage(named: "messages-tab")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
        items[1].image = UIImage(named: "proxies-tab")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
        items[2].image = UIImage(named: "me-tab")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
    }
}
