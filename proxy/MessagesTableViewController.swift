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
    
    var unreadRef = FIRDatabaseReference()
    var unreadRefHandle = FIRDatabaseHandle()
    
    var convosRef = FIRDatabaseReference()
    var convosRefHandle = FIRDatabaseHandle()
    var convos = [Convo]()
    var convosToLeave = [Convo]()
    
    var convo = Convo()
    var shouldShowConvo = false
    
    var newMessageButton = UIBarButtonItem()
    var newProxyButton = UIBarButtonItem()
    var leaveConvosButton = UIBarButtonItem()
    var confirmLeaveConvosButton = UIBarButtonItem()
    var cancelLeaveConvosButton = UIBarButtonItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        checkLogInStatus()
        tabBarController?.tabBar.items?.first?.image = UIImage(named: "messages-tab")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        showNewConvo()
    }
    
    deinit {
        unreadRef.removeObserverWithHandle(unreadRefHandle)
        convosRef.removeObserverWithHandle(convosRefHandle)
    }
    
    // MARK: - Log in
    func checkLogInStatus() {
        FIRAuth.auth()?.addAuthStateDidChangeListener { (auth, user) in
            if let user = user {
                self.api.uid = user.uid
                self.observeUnread()
                self.observeConvos()
            } else {
                self.showLogInViewController()
            }
        }
    }
    
    func showLogInViewController() {
        let dest = self.storyboard!.instantiateViewControllerWithIdentifier(Identifiers.LogInViewController) as! LogInViewController
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController = dest
    }
    
    // MARK: - Set up
    func setUp() {
        navigationItem.title = "Messages"
        newMessageButton = createNewMessageButton()
        newProxyButton = createNewProxyButton()
        leaveConvosButton = createLeaveConvosButton()
        confirmLeaveConvosButton = createConfirmLeaveConvosButton()
        cancelLeaveConvosButton = createCancelDeleteProxiesButton()
        setDefaultButtons()
        edgesForExtendedLayout = .All
        tableView.rowHeight = 80
        tableView.estimatedRowHeight = 80
        tableView.allowsMultipleSelectionDuringEditing = true
    }
    
    func createNewMessageButton() -> UIBarButtonItem {
        let newMessageButton = UIButton(type: .Custom)
        newMessageButton.setImage(UIImage(named: "new-message.png"), forState: UIControlState.Normal)
        newMessageButton.addTarget(self, action: #selector(MessagesTableViewController.showNewMessageViewController), forControlEvents: UIControlEvents.TouchUpInside)
        newMessageButton.frame = CGRectMake(0, 0, 25, 25)
        return UIBarButtonItem(customView: newMessageButton)
    }
    
    func createNewProxyButton() -> UIBarButtonItem {
        let newProxyButton = UIButton(type: .Custom)
        newProxyButton.setImage(UIImage(named: "new-proxy.png"), forState: UIControlState.Normal)
        newProxyButton.addTarget(self, action: #selector(MessagesTableViewController.createNewProxy), forControlEvents: UIControlEvents.TouchUpInside)
        newProxyButton.frame = CGRectMake(0, 0, 25, 25)
        return UIBarButtonItem(customView: newProxyButton)
    }
    
    func createLeaveConvosButton() -> UIBarButtonItem {
        let leaveConvosButton = UIButton(type: .Custom)
        leaveConvosButton.setImage(UIImage(named: "delete.png"), forState: UIControlState.Normal)
        leaveConvosButton.addTarget(self, action: #selector(MessagesTableViewController.toggleEditMode), forControlEvents: UIControlEvents.TouchUpInside)
        leaveConvosButton.frame = CGRectMake(0, 0, 25, 25)
        return UIBarButtonItem(customView: leaveConvosButton)
    }
    
    func createConfirmLeaveConvosButton() -> UIBarButtonItem {
        let confirmLeaveConvosButton = UIButton(type: .Custom)
        confirmLeaveConvosButton.setImage(UIImage(named: "confirm"), forState: UIControlState.Normal)
        confirmLeaveConvosButton.addTarget(self, action: #selector(MessagesTableViewController.leaveSelectedConvos), forControlEvents: UIControlEvents.TouchUpInside)
        confirmLeaveConvosButton.frame = CGRectMake(0, 0, 25, 25)
        return UIBarButtonItem(customView: confirmLeaveConvosButton)
    }
    
    func createCancelDeleteProxiesButton() -> UIBarButtonItem {
        let cancelDeleteProxiesButton = UIButton(type: .Custom)
        cancelDeleteProxiesButton.setImage(UIImage(named: "cancel"), forState: UIControlState.Normal)
        cancelDeleteProxiesButton.addTarget(self, action: #selector(MessagesTableViewController.toggleEditMode), forControlEvents: UIControlEvents.TouchUpInside)
        cancelDeleteProxiesButton.frame = CGRectMake(0, 0, 25, 25)
        return UIBarButtonItem(customView: cancelDeleteProxiesButton)
    }
    
    func setDefaultButtons() {
        navigationItem.leftBarButtonItem = leaveConvosButton
        navigationItem.rightBarButtonItems = [newMessageButton, newProxyButton]
    }
    
    func setEditModeButtons() {
        navigationItem.leftBarButtonItem = cancelLeaveConvosButton
        navigationItem.rightBarButtonItems = [confirmLeaveConvosButton]
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
    
    func createNewProxy() {
        api.create { (proxy) in
            self.api.save(proxy: proxy!, withNickname: "")
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.CreatedNewProxyFromHomeTab, object: nil)
            self.tabBarController?.selectedIndex = 1
        }
    }
    
    // MARK: - Database
    func observeUnread() {
        unreadRef = ref.child("unread").child(api.uid)
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let unread = snapshot.value as? Int {
                self.navigationItem.title = "Messages \(unread.toTitleSuffix())"
                self.tabBarController?.tabBar.items?.first?.badgeValue = String(unread)
            }
        })
    }
    
    func observeConvos() {
        convosRef = ref.child("convos").child(api.uid)
        convosRefHandle = convosRef.queryOrderedByChild("timestamp").observeEventType(.Value, withBlock: { (snapshot) in
            var convos = [Convo]()
            for child in snapshot.children {
                let convo = Convo(anyObject: child.value)
                if !convo.didLeaveConvo {
                    convos.append(convo)
                }
            }
            self.convos = convos.reverse()
            self.tableView.reloadData()
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
    
    // MARK: - Table view data source
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.ConvoCell, forIndexPath: indexPath) as! ConvoCell
        cell.convo = convos[indexPath.row]
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
        dest.delegate = self
        navigationController?.pushViewController(dest, animated: true)
    }
    
    func showConvo(convo: Convo) {
        let dest = self.storyboard!.instantiateViewControllerWithIdentifier(Identifiers.ConvoViewController) as! ConvoViewController
        dest.convo = convo
        navigationController!.pushViewController(dest, animated: true)
    }
}
