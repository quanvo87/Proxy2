//
//  MessagesTableViewController.swift
//  proxy
//
//  Created by Quan Vo on 9/10/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class MessagesTableViewController: UITableViewController, NewMessageViewControllerDelegate {
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    
    var convosRef = FIRDatabaseReference()
    var convosRefHandle = FIRDatabaseHandle()
    var convos = [Convo]()
    var convosToLeave = [Convo]()
    
    var unreadRef = FIRDatabaseReference()
    var unreadRefHandle = FIRDatabaseHandle()
    
    var convo = Convo()
    var shouldShowConvo = false
    
    var newMessageBarButton = UIBarButtonItem()
    var newProxyBarButton = UIBarButtonItem()
    var leaveConvosBarButton = UIBarButtonItem()
    var confirmLeaveConvosBarButton = UIBarButtonItem()
    var cancelLeaveConvosBarButton = UIBarButtonItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let items = self.tabBarController?.tabBar.items
        let size = CGSize(width: 30, height: 30)
        let isAspectRatio = true
        items![0].image = UIImage(named: "messages-tab")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
        items![1].image = UIImage(named: "proxies-tab")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
        items![2].image = UIImage(named: "me-tab")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
        
        navigationItem.title = "Messages"
        
        let newMessageButton = UIButton(type: .Custom)
        newMessageButton.setImage(UIImage(named: "new-message.png"), forState: UIControlState.Normal)
        newMessageButton.addTarget(self, action: #selector(MessagesTableViewController.showNewMessageViewController), forControlEvents: UIControlEvents.TouchUpInside)
        newMessageButton.frame = CGRectMake(0, 0, 25, 25)
        newMessageBarButton = UIBarButtonItem(customView: newMessageButton)
        
        let newProxyButton = UIButton(type: .Custom)
        newProxyButton.setImage(UIImage(named: "new-proxy.png"), forState: UIControlState.Normal)
        newProxyButton.addTarget(self, action: #selector(MessagesTableViewController.createNewProxy), forControlEvents: UIControlEvents.TouchUpInside)
        newProxyButton.frame = CGRectMake(0, 0, 25, 25)
        newProxyBarButton = UIBarButtonItem(customView: newProxyButton)
        
        let leaveConvosButton = UIButton(type: .Custom)
        leaveConvosButton.setImage(UIImage(named: "delete.png"), forState: UIControlState.Normal)
        leaveConvosButton.addTarget(self, action: #selector(MessagesTableViewController.toggleEditMode), forControlEvents: UIControlEvents.TouchUpInside)
        leaveConvosButton.frame = CGRectMake(0, 0, 25, 25)
        leaveConvosBarButton = UIBarButtonItem(customView: leaveConvosButton)
        
        let confirmLeaveConvosButton = UIButton(type: .Custom)
        confirmLeaveConvosButton.setImage(UIImage(named: "confirm"), forState: UIControlState.Normal)
        confirmLeaveConvosButton.addTarget(self, action: #selector(MessagesTableViewController.confirmLeaveConvos), forControlEvents: UIControlEvents.TouchUpInside)
        confirmLeaveConvosButton.frame = CGRectMake(0, 0, 25, 25)
        confirmLeaveConvosBarButton = UIBarButtonItem(customView: confirmLeaveConvosButton)
        
        let cancelDeleteProxiesButton = UIButton(type: .Custom)
        cancelDeleteProxiesButton.setImage(UIImage(named: "cancel"), forState: UIControlState.Normal)
        cancelDeleteProxiesButton.addTarget(self, action: #selector(MessagesTableViewController.toggleEditMode), forControlEvents: UIControlEvents.TouchUpInside)
        cancelDeleteProxiesButton.frame = CGRectMake(0, 0, 25, 25)
        cancelLeaveConvosBarButton = UIBarButtonItem(customView: cancelDeleteProxiesButton)
        
        setDefaultButtons()
        
        edgesForExtendedLayout = .All
        tableView.rowHeight = 80
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .None
        tableView.allowsMultipleSelectionDuringEditing = true
        
        FIRAuth.auth()?.addAuthStateDidChangeListener { (auth, user) in
            if let user = user {
                self.api.uid = user.uid
                self.observeConvos()
                self.observeUnread()
            } else {
                let dest = self.storyboard!.instantiateViewControllerWithIdentifier(Identifiers.LogInViewController) as! LogInViewController
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                appDelegate.window?.rootViewController = dest
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        showNewConvo()
    }
    
    deinit {
        convosRef.removeObserverWithHandle(convosRefHandle)
        unreadRef.removeObserverWithHandle(unreadRefHandle)
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
        tableView.setEditing(!tableView.editing, animated: true)
        if tableView.editing {
            setEditModeButtons()
        } else {
            setDefaultButtons()
            convosToLeave = []
        }
    }
    
    func leaveSelectedConvos() {
        tableView.setEditing(false, animated: true)
        setDefaultButtons()
        for convo in convosToLeave {
            api.leave(convo: convo)
        }
        convosToLeave = []
    }
    
    func confirmLeaveConvos() {
        if convosToLeave.isEmpty {
            toggleEditMode()
            return
        }
        let alert = UIAlertController(title: "Leave Conversations?", message: "This will hide them until you receive another message in them.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action) in
            self.leaveSelectedConvos()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func createNewProxy() {
        navigationItem.rightBarButtonItems![1].enabled = false
        api.create { (proxy) in
            self.navigationItem.rightBarButtonItems![1].enabled = true
            guard proxy != nil else {
                self.showAlert("Proxy Limit Reached", message: "Cannot exceed 50 proxies. Delete some old ones, then try again!")
                return
            }
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.CreatedNewProxyFromHomeTab, object: nil)
            self.tabBarController?.selectedIndex = 1
        }
    }
    
    func observeConvos() {
        convosRef = ref.child(Path.Convos).child(api.uid)
        convosRefHandle = convosRef.queryOrderedByChild(Path.Timestamp).observeEventType(.Value, withBlock: { (snapshot) in
            self.convos = self.api.getConvos(fromSnapshot: snapshot)
            self.tableView.reloadData()
        })
    }
    
    func observeUnread() {
        unreadRef = ref.child(Path.Unread).child(api.uid).child(Path.Unread)
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let unread = snapshot.value as? Int {
                self.navigationItem.title = "Messages \(unread.toTitleSuffix())"
                self.tabBarController?.tabBar.items?.first?.badgeValue = unread == 0 ? nil : String(unread)
            } else {
                self.navigationItem.title = "Messages"
                self.tabBarController?.tabBar.items?.first?.badgeValue = nil
            }
        })
    }
    
    // MARK: - Table view delegate
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return convos.count
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.min
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let convo = convos[indexPath.row]
        if !tableView.editing {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            showConvo(convo)
        } else {
            convosToLeave.append(convo)
        }
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        var index = 0
        let convo = convos[indexPath.row]
        for _convo in convosToLeave {
            if _convo.key == convo.key {
                convosToLeave.removeAtIndex(index)
                return
            }
            index += 1
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.ConvoCell, forIndexPath: indexPath) as! ConvoCell
        let convo = convos[indexPath.row]
        
        cell.iconImageView.kf_indicatorType = .Activity
        cell.iconImageView.image = nil
        api.getURL(forIcon: convo.icon) { (url) in
            guard let url = url else { return }
            cell.iconImageView.kf_setImageWithURL(url, placeholderImage: nil)
        }
        
        cell.titleLabel.attributedText = api.getConvoTitle(receiverNickname: convo.receiverNickname, receiverName: convo.receiverProxy, senderNickname: convo.senderNickname, senderName: convo.senderProxy)
        cell.lastMessageLabel.text = convo.message
        cell.timestampLabel.text = convo.timestamp.toTimeAgo()
        cell.unreadLabel.text = convo.unread.toNumberLabel()
        
        return cell
    }
    
    // MARK: - Select proxy view controller delegate
    func showNewConvo(convo: Convo) {
        self.convo = convo
        shouldShowConvo = true
    }
    
    func showNewConvo() {
        if shouldShowConvo {
            let dest = self.storyboard!.instantiateViewControllerWithIdentifier(Identifiers.ConvoViewController) as! ConvoViewController
            dest.convo = convo
            shouldShowConvo = false
            self.navigationController!.pushViewController(dest, animated: true)
        }
    }
    
    // MARK: - Navigation
    func showNewMessageViewController() {
        let dest = self.storyboard!.instantiateViewControllerWithIdentifier(Identifiers.NewMessageViewController) as! NewMessageViewController
        dest.newMessageViewControllerDelegate = self
        navigationController?.pushViewController(dest, animated: true)
    }
    
    func showConvo(convo: Convo) {
        let dest = self.storyboard!.instantiateViewControllerWithIdentifier(Identifiers.ConvoViewController) as! ConvoViewController
        dest.convo = convo
        navigationController!.pushViewController(dest, animated: true)
    }
}
