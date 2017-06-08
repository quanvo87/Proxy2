//
//  MessagesTableViewController.swift
//  proxy
//
//  Created by Quan Vo on 9/10/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase

class MessagesTableViewController: UITableViewController {
    let api = API.sharedInstance

    var newProxyButton = UIBarButtonItem()
    var newMessageButton = UIBarButtonItem()
    var leaveConvosButton = UIBarButtonItem()
    var confirmButton = UIBarButtonItem()
    var cancelButton = UIBarButtonItem()

    var authHandle: AuthStateDidChangeListenerHandle?
    var dataSource = MessagesTableViewDataSource()
    var unreadRef = DatabaseReference()
    var unreadHandle = DatabaseHandle()
    var convos = [Convo]()
    var convosToLeave = [Convo]()

    var convo: Convo?
    var shouldGoToNewConvo = false

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Messages"

        newProxyButton = ButtonFactory.makeNewProxyButton(target: self, selector: #selector(MessagesTableViewController.createNewProxy))
        newMessageButton = ButtonFactory.makeNewMessageButton(target: self, selector: #selector(MessagesTableViewController.goToNewMessageViewController))
        leaveConvosButton = ButtonFactory.makeDeleteButton(target: self, selector: #selector(MessagesTableViewController.toggleEditMode))
        confirmButton = ButtonFactory.makeConfirmButton(target: self, selector: #selector(MessagesTableViewController.leaveConvos))
        cancelButton = ButtonFactory.makeCancelButton(target: self, selector: #selector(MessagesTableViewController.toggleEditMode))
        setDefaultButtons()

        edgesForExtendedLayout = .all
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.rowHeight = 80
        tableView.separatorStyle = .none

        let items = self.tabBarController?.tabBar.items
        let size = CGSize(width: 30, height: 30)
        let isAspectRatio = true
        items![0].image = UIImage(named: "messages-tab")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
        items![1].image = UIImage(named: "proxies-tab")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
        items![2].image = UIImage(named: "me-tab")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)

        authHandle = Auth.auth().addStateDidChangeListener { (_, user) in
            guard let user = user else {
                let dest = self.storyboard!.instantiateViewController(withIdentifier: Identifiers.LogInViewController) as! LogInViewController
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.window?.rootViewController = dest
                return
            }
            UserManager.shared.uid = user.uid

            self.dataSource = MessagesTableViewDataSource()
            self.dataSource.tableViewController = self
            self.tableView.dataSource = self.dataSource
            self.tableView.reloadData()

            self.api.uid = user.uid
            self.observeUnread()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if shouldGoToNewConvo, let convo = convo {
            shouldGoToNewConvo = false
            self.convo = nil
            let dest = storyboard!.instantiateViewController(withIdentifier: Identifiers.ConvoViewController) as! ConvoViewController
            dest.convo = convo
            navigationController!.pushViewController(dest, animated: true)
        }
    }

    deinit {
        if let authHandle = authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
        unreadRef.removeObserver(withHandle: unreadHandle)
    }
}

extension MessagesTableViewController {
    func setDefaultButtons() {
        navigationItem.leftBarButtonItem = leaveConvosButton
        navigationItem.rightBarButtonItems = [newMessageButton, newProxyButton]
    }

    func setEditModeButtons() {
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItems = [confirmButton]
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

    func leaveConvos() {
        if convosToLeave.isEmpty {
            toggleEditMode()
            return
        }
        let alert = UIAlertController(title: "Leave Conversations?", message: "This will hide them until you receive another message in them.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Leave", style: .destructive, handler: { (action) in
            self.tableView.setEditing(false, animated: true)
            self.setDefaultButtons()
            for convo in self.convosToLeave {
                self.api.leaveConvo(convo)
            }
            self.convosToLeave = []
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func createNewProxy() {
        navigationItem.rightBarButtonItems![1].isEnabled = false
        api.createProxy { (proxy) in
            self.navigationItem.rightBarButtonItems![1].isEnabled = true
            guard proxy != nil else {
                self.showAlert("Cannot Exceed 50 Proxies", message: "Delete some proxies and try again!")
                return
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: Notifications.CreatedNewProxyFromHomeTab), object: nil)
            self.tabBarController?.selectedIndex = 1
        }
    }

    func goToNewMessageViewController() {
        let dest = self.storyboard!.instantiateViewController(withIdentifier: Identifiers.NewMessageViewController) as! NewMessageViewController
        dest.newMessageViewControllerDelegate = self
        navigationController?.pushViewController(dest, animated: true)
    }
}

extension MessagesTableViewController {
    func observeUnread() {
        unreadRef = api.ref.child(Path.Unread).child(api.uid).child(Path.Unread)
        unreadHandle = unreadRef.observe(.value, with: { (snapshot) in
            if let unread = snapshot.value as? Int {
                self.navigationItem.title = "Messages \(unread.toTitleSuffix())"
                self.tabBarController?.tabBar.items?.first?.badgeValue = unread == 0 ? nil : String(unread)
            } else {
                self.navigationItem.title = "Messages"
                self.tabBarController?.tabBar.items?.first?.badgeValue = nil
            }
        })
    }
}

extension MessagesTableViewController {
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

extension MessagesTableViewController: NewMessageViewControllerDelegate {
    func goToNewConvo(_ convo: Convo) {
        self.convo = convo
        shouldGoToNewConvo = true
    }
}
