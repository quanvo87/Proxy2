//
//  MessagesTableViewController.swift
//  proxy
//
//  Created by Quan Vo on 9/10/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

class MessagesTableViewController: UITableViewController {
    var authManager: AuthManager?
    var navigationItemManager: NavigationItemManager?
    var dataSource: MessagesTableViewDataSource?
    var unreadManager: UnreadManager?

    var convosToLeave = [Convo]()

    var convo: Convo?
    var shouldGoToNewConvo = false

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Messages"
        edgesForExtendedLayout = .all
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.rowHeight = 80
        tableView.separatorStyle = .none

        authManager = AuthManager(self)
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

extension MessagesTableViewController: AuthManagerDelegate {
    func logIn() {
        navigationItemManager = NavigationItemManager(self)
        setDefaultButtons()

        TabBarManager.setUpTabBarItems(self.tabBarController?.tabBar.items)

        dataSource = MessagesTableViewDataSource(self)
        tableView.dataSource = dataSource

        unreadManager = UnreadManager(self)
    }

    func logOut() {
        if  let dest = self.storyboard?.instantiateViewController(withIdentifier: Identifiers.LogInViewController) as? LogInViewController,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.window?.rootViewController = dest
        }
    }
}

extension MessagesTableViewController: NavigationItemManagerDelegate {
    func setDefaultButtons() {
        navigationItem.leftBarButtonItem = navigationItemManager?.removeItemsButton
        navigationItem.rightBarButtonItems = [navigationItemManager?.newMessageButton ?? UIBarButtonItem(),
                                              navigationItemManager?.newProxyButton ?? UIBarButtonItem()]
    }

    func setEditModeButtons() {
        navigationItem.leftBarButtonItem = navigationItemManager?.cancelButton
        navigationItem.rightBarButtonItems = [navigationItemManager?.confirmButton ?? UIBarButtonItem()]
    }

    func toggleEditMode() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        if tableView.isEditing {
            setEditModeButtons()
        } else {
            setDefaultButtons()
            convosToLeave = []
        }
    }

    func removeItems() {
        if convosToLeave.isEmpty {
            toggleEditMode()
            return
        }
        let alert = UIAlertController(title: "Leave Conversations?", message: "This will hide them until you receive another message in them.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Leave", style: .destructive, handler: { (action) in
            self.tableView.setEditing(false, animated: true)
            self.setDefaultButtons()
            for convo in self.convosToLeave {
                API.sharedInstance.leaveConvo(convo)
            }
            self.convosToLeave = []
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
        if let convos = dataSource?.convosManager.convos {
            return convos
        } else {
            return []
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let convo = convos[indexPath.row]
        if tableView.isEditing {
            convosToLeave.append(convo)
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
            convosToLeave.remove(at: index)
        }
    }
}

extension MessagesTableViewController: UnreadManagerDelegate {
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

// TODO: - revisit logic
extension MessagesTableViewController: NewMessageViewControllerDelegate {
    func goToNewConvo(_ convo: Convo) {
        self.convo = convo
        shouldGoToNewConvo = true
    }
}
