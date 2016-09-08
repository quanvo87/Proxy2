//
//  MessagesViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/25/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase

class MessagesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NewMessageViewControllerDelegate {
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var convosRef = FIRDatabaseReference()
    var unreadRef = FIRDatabaseReference()
    var convosRefHandle = FIRDatabaseHandle()
    var unreadRefHandle = FIRDatabaseHandle()
    var convos = [Convo]()
    var convo = Convo()
    var shouldShowConvo = false
    
    @IBOutlet weak var newMessageButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
        
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if let user = user {
                self.api.uid = user.uid
                self.observeUnread()
                self.observeConvos()
            } else {
                let dest = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.Identifiers.LogInViewController) as! LogInViewController
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                appDelegate.window?.rootViewController = dest
            }
        }
        
        setUpTableView()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        if shouldShowConvo {
            let dest = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.Identifiers.ConvoViewController) as! ConvoViewController
            dest.convo = convo
            dest.hidesBottomBarWhenPushed = true
            shouldShowConvo = false
            convo = Convo()
            self.navigationController!.pushViewController(dest, animated: true)
        }
    }
    
    deinit {
        convosRef.removeObserverWithHandle(convosRefHandle)
        unreadRef.removeObserverWithHandle(unreadRefHandle)
    }
    
    // MARK: - UI
    
    func setUpUI() {
        title = "Messages"
        addNavBarButtons()
    }
    
    func addNavBarButtons() {
        // New Message Button
        let newMessageButton = UIButton(type: .Custom)
        newMessageButton.setImage(UIImage(named: "new-message.png"), forState: UIControlState.Normal)
        newMessageButton.addTarget(self, action: #selector(MessagesViewController.tapNewMessageButton), forControlEvents: UIControlEvents.TouchUpInside)
        newMessageButton.frame = CGRectMake(0, 0, 24, 24)
        let newMessageBarButton = UIBarButtonItem(customView: newMessageButton)
        
        // New Proxy Button
        let newProxyButton = UIButton(type: .Custom)
        newProxyButton.setImage(UIImage(named: "new-proxy.png"), forState: UIControlState.Normal)
        newProxyButton.addTarget(self, action: #selector(MessagesViewController.tapNewProxyButton), forControlEvents: UIControlEvents.TouchUpInside)
        newProxyButton.frame = CGRectMake(0, 0, 26, 26)
        let newProxyBarButton = UIBarButtonItem(customView: newProxyButton)
        
        self.navigationItem.rightBarButtonItems = [newMessageBarButton, newProxyBarButton]
    }
    
    // MARK: - Database
    
    func observeUnread() {
        unreadRef = ref.child("users").child(api.uid).child("unread")
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let unread = snapshot.value as? Int {
                self.title = "Messages \(unread.unreadTitleSuffix())"
            }
        })
    }
    
    func observeConvos() {
        convosRef = ref.child("users").child(api.uid).child("convos")
        convosRefHandle = convosRef.queryOrderedByChild("timestamp").observeEventType(.Value, withBlock: { (snapshot) in
            var convos = [Convo]()
            for child in snapshot.children {
                var convo = Convo(anyObject: child.value)
                convo.unread = child.value["unread"] as? Int ?? 0
                convos.append(convo)
            }
            self.convos = convos.reverse()
            self.tableView.reloadData()
        })
    }
    
    // MARK: - Table view
    
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        automaticallyAdjustsScrollViewInsets = false
        tableView.rowHeight = 80
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .None
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return convos.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Identifiers.ProxyCell, forIndexPath: indexPath) as! ProxyCell
        let convo = self.convos[indexPath.row]
        cell.titleLabel.text = convo.receiverProxy
        cell.timestampLabel.text = convo.timestamp.timeAgoFromTimeInterval()
        cell.messageLabel.text = convo.message
        cell.accessoryType = .None
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - Select proxy view controller delegate
    
    func showNewConvo(convo: Convo) {
        self.convo = convo
        shouldShowConvo = true
    }
    
    // MARK: - Navigation
    
    func tapNewMessageButton() {
        let dest = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.Identifiers.NewMessageViewController) as! NewMessageViewController
        dest.delegate = self
        let nav = UINavigationController.init(rootViewController: dest)
        nav.modalTransitionStyle = .CoverVertical
        presentViewController(nav, animated: true, completion: nil)
    }
    
    func tapNewProxyButton() {
        let dest = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.Identifiers.NewProxyViewController) as! NewProxyViewController
        let nav = UINavigationController.init(rootViewController: dest)
        nav.modalTransitionStyle = .CoverVertical
        presentViewController(nav, animated: true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case Constants.Segues.ConvoSegue:
            if let dest = segue.destinationViewController as? ConvoViewController,
                let index = tableView.indexPathForSelectedRow?.row {
                dest.convo = convos[index]
                dest.hidesBottomBarWhenPushed = true
            }
        default:
            return
        }
    }
}