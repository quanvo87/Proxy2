//
//  HomeViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/25/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NewMessageViewControllerDelegate {
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var convosRef = FIRDatabaseReference()
    var unreadRef = FIRDatabaseReference()
    var convosRefHandle = FIRDatabaseHandle()
    var unreadRefHandle = FIRDatabaseHandle()
    var convos = [Convo]()
    var convo = Convo()
    var shouldShowConvo = false
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Home"
        
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
    
    func observeUnread() {
        unreadRef = ref.child("users").child(api.uid).child("unread")
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let unread = snapshot.value as? Int {
                self.title = "Home \(unread.unreadTitleSuffix())"
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
        automaticallyAdjustsScrollViewInsets = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return convos.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Identifiers.ProxyCell, forIndexPath: indexPath) as! ProxyCell
        let convo = self.convos[indexPath.row]
        cell.titleLabel.attributedText = convoTitle(convo.convoNickname, proxyNickname: convo.proxyNickname, you: convo.senderProxy, them: convo.receiverProxy, size: 13, navBar: false)
        cell.timestampLabel.text = convo.timestamp.timeAgoFromTimeInterval()
        cell.messageLabel.text = convo.message
        cell.unreadLabel.text = convo.unread.unreadFormatted()
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case Constants.Segues.NewMessageSegue:
            if let dest = segue.destinationViewController as? NewMessageViewController {
                dest.delegate = self
            }
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