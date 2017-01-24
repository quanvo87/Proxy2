//
//  MessagesTableViewController.swift
//  proxy
//
//  Created by Quan Vo on 9/10/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase

class MessagesTableViewController: UITableViewController, NewMessageViewControllerDelegate {
    
    let api = API.sharedInstance
    
    var leaveConvosBarButton = UIBarButtonItem()
    var newProxyBarButton = UIBarButtonItem()
    var newMessageBarButton = UIBarButtonItem()
    var confirmLeaveConvosBarButton = UIBarButtonItem()
    var cancelLeaveConvosBarButton = UIBarButtonItem()
    
    var unreadRef = FIRDatabaseReference()
    var unreadRefHandle = FIRDatabaseHandle()
    
    var convosRef = FIRDatabaseReference()
    var convosRefHandle = FIRDatabaseHandle()
    var convos = [Convo]()
    var convosToLeave = [Convo]()
    
    var convo = Convo()
    var shouldGoToNewConvo = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Messages"
        
        let leaveConvosButton = UIButton(type: .custom)
        leaveConvosButton.addTarget(self, action: #selector(MessagesTableViewController.toggleEditMode), for: UIControlEvents.touchUpInside)
        leaveConvosButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        leaveConvosButton.setImage(UIImage(named: "delete.png"), for: UIControlState.normal)
        leaveConvosBarButton = UIBarButtonItem(customView: leaveConvosButton)
        
        let newProxyButton = UIButton(type: .custom)
        newProxyButton.addTarget(self, action: #selector(MessagesTableViewController.createNewProxy), for: UIControlEvents.touchUpInside)
        newProxyButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        newProxyButton.setImage(UIImage(named: "new-proxy.png"), for: UIControlState.normal)
        newProxyBarButton = UIBarButtonItem(customView: newProxyButton)
        
        let newMessageButton = UIButton(type: .custom)
        newMessageButton.addTarget(self, action: #selector(MessagesTableViewController.goToNewMessage), for: UIControlEvents.touchUpInside)
        newMessageButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        newMessageButton.setImage(UIImage(named: "new-message.png"), for: UIControlState.normal)
        newMessageBarButton = UIBarButtonItem(customView: newMessageButton)
        
        let confirmLeaveConvosButton = UIButton(type: .custom)
        confirmLeaveConvosButton.addTarget(self, action: #selector(MessagesTableViewController.leaveConvos), for: UIControlEvents.touchUpInside)
        confirmLeaveConvosButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        confirmLeaveConvosButton.setImage(UIImage(named: "confirm"), for: UIControlState.normal)
        confirmLeaveConvosBarButton = UIBarButtonItem(customView: confirmLeaveConvosButton)
        
        let cancelDeleteProxiesButton = UIButton(type: .custom)
        cancelDeleteProxiesButton.addTarget(self, action: #selector(MessagesTableViewController.toggleEditMode), for: UIControlEvents.touchUpInside)
        cancelDeleteProxiesButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        cancelDeleteProxiesButton.setImage(UIImage(named: "cancel"), for: UIControlState.normal)
        cancelLeaveConvosBarButton = UIBarButtonItem(customView: cancelDeleteProxiesButton)
        
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
        
        FIRAuth.auth()?.addStateDidChangeListener { (auth, user) in
            guard let user = user else {
                let dest = self.storyboard!.instantiateViewController(withIdentifier: Identifiers.LogInViewController) as! LogInViewController
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.window?.rootViewController = dest
                return
            }
            self.api.uid = user.uid
            self.observeUnread()
            self.observeConvos()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if shouldGoToNewConvo {
            let dest = self.storyboard!.instantiateViewController(withIdentifier: Identifiers.ConvoViewController) as! ConvoViewController
            dest.convo = convo
            shouldGoToNewConvo = false
            navigationController!.pushViewController(dest, animated: true)
        }
    }
    
    deinit {
        unreadRef.removeObserver(withHandle: unreadRefHandle)
        convosRef.removeObserver(withHandle: convosRefHandle)
    }
    
    func setDefaultButtons() {
        navigationItem.leftBarButtonItem = leaveConvosBarButton
        navigationItem.rightBarButtonItems = [newMessageBarButton, newProxyBarButton]
    }
    
    func setEditModeButtons() {
        navigationItem.leftBarButtonItem = cancelLeaveConvosBarButton
        navigationItem.rightBarButtonItems = [confirmLeaveConvosBarButton]
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
    
    func observeUnread() {
        unreadRef = api.ref.child(Path.Unread).child(api.uid).child(Path.Unread)
        unreadRefHandle = unreadRef.observe(.value, with: { (snapshot) in
            if let unread = snapshot.value as? Int {
                self.navigationItem.title = "Messages \(unread.toTitleSuffix())"
                self.tabBarController?.tabBar.items?.first?.badgeValue = unread == 0 ? nil : String(unread)
            } else {
                self.navigationItem.title = "Messages"
                self.tabBarController?.tabBar.items?.first?.badgeValue = nil
            }
        })
    }
    
    func observeConvos() {
        convosRef = api.ref.child(Path.Convos).child(api.uid)
        convosRefHandle = convosRef.queryOrdered(byChild: Path.Timestamp).observe(.value, with: { (snapshot) in
            self.convos = self.api.getConvos(from: snapshot)
            self.tableView.reloadData()
        })
    }
    
    func goToNewMessage() {
        let dest = self.storyboard!.instantiateViewController(withIdentifier: Identifiers.NewMessageViewController) as! NewMessageViewController
        dest.newMessageViewControllerDelegate = self
        navigationController?.pushViewController(dest, animated: true)
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return convos.count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let convo = convos[indexPath.row]
        if !tableView.isEditing {
            tableView.deselectRow(at: indexPath, animated: true)
            let dest = storyboard!.instantiateViewController(withIdentifier: Identifiers.ConvoViewController) as! ConvoViewController
            dest.convo = convo
            navigationController!.pushViewController(dest, animated: true)
        } else {
            convosToLeave.append(convo)
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        var index = 0
        let convo = convos[indexPath.row]
        for convo_ in convosToLeave {
            if convo_.key == convo.key {
                convosToLeave.remove(at: index)
                return
            }
            index += 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.ConvoCell, for: indexPath as IndexPath) as! ConvoCell
        let convo = convos[indexPath.row]
        
        cell.iconImageView.image = nil
        cell.iconImageView.kf.indicatorType = .activity
        api.getURL(forIconName: convo.icon) { (url) in
            cell.iconImageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: nil)
        }
        
        cell.titleLabel.attributedText = api.getConvoTitle(receiverNickname: convo.receiverNickname, receiverName: convo.receiverProxyName, senderNickname: convo.senderNickname, senderName: convo.senderProxyName)
        cell.lastMessageLabel.text = convo.message
        cell.timestampLabel.text = convo.timestamp.toTimeAgo()
        cell.unreadLabel.text = convo.unread.toNumberLabel()
        
        return cell
    }
    
    // MARK: - New message view controller delegate
    func goToNewConvo(_ convo: Convo) {
        self.convo = convo
        shouldGoToNewConvo = true
    }
}
