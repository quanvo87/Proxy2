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
    
    private let api = API.sharedInstance
    private let ref = FIRDatabase.database().reference()
    private var convosRef = FIRDatabaseReference()
    private var unreadRef = FIRDatabaseReference()
    private var convosRefHandle = FIRDatabaseHandle()
    private var unreadRefHandle = FIRDatabaseHandle()
    private var convos = [Convo]()
    private var unread = 0
    private var convo = Convo()
    private var showConvo = false
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if let user = user {
                self.api.uid = user.uid
                self.configureDatabase()
            } else {
                let logInViewController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.Identifiers.LogInViewController) as! LogInViewController
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                appDelegate.window?.rootViewController = logInViewController
            }
        }
        
        setUpTableView()
    }
    
    override func viewWillAppear(animated: Bool) {
        setTitle()
    }
    
    override func viewDidAppear(animated: Bool) {
        if showConvo {
            let convoViewController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.Identifiers.ConvoViewController) as! ConvoViewController
            convoViewController.convo = convo
            showConvo = false
            convo = Convo()
            self.navigationController!.pushViewController(convoViewController, animated: true)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationItem.title = unread.unreadTitleSuffix()
    }
    
    deinit {
        convosRef.removeObserverWithHandle(convosRefHandle)
        unreadRef.removeObserverWithHandle(unreadRefHandle)
    }
    
    func setTitle() {
        title = "Messages \(unread.unreadTitleSuffix())"
    }
    
    func configureDatabase() {
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
        
        unreadRef = ref.child("users").child(api.uid).child("unread")
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let unread = snapshot.value as? Int {
                self.unread = unread
                self.setTitle()
            }
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
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Identifiers.ProxyTableViewCell, forIndexPath: indexPath) as! ProxyTableViewCell
        
        let convo = self.convos[indexPath.row]
        
        let title: NSMutableAttributedString
        let subtitle: NSMutableAttributedString
        
        if convo.nickname == "" {
            let attributes = [NSFontAttributeName : UIFont.boldSystemFontOfSize(14)]
            let you = NSMutableAttributedString(string: convo.senderProxy, attributes:attributes)
            let them = NSMutableAttributedString(string: ", " + convo.receiverProxy)
            you.appendAttributedString(them)
            title = you
            subtitle = NSMutableAttributedString(string: "Members")
        } else {
            var attributes = [NSFontAttributeName : UIFont.boldSystemFontOfSize(10)]
            let you = NSMutableAttributedString(string: convo.senderProxy, attributes:attributes)
            let them = NSMutableAttributedString(string: ", " + convo.receiverProxy)
            you.appendAttributedString(them)
            attributes = [NSFontAttributeName : UIFont.boldSystemFontOfSize(14)]
            title = NSMutableAttributedString(string: convo.nickname, attributes: attributes)
            subtitle = you
        }
        
        cell.titleLabel.attributedText = title
        cell.subtitleLabel.attributedText = subtitle
        cell.timestampLabel.text = convo.timestamp.timeAgoFromTimeInterval()
        cell.messageLabel.text = convo.message
        cell.unreadLabel.text = convo.unread.unreadFormatted()
        
        return cell
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case Constants.Segues.NewMessageSegue:
            if let destination = segue.destinationViewController as? NewMessageViewController {
                destination.delegate = self
            }
        case Constants.Segues.ConvoSegue:
            if let destination = segue.destinationViewController as? ConvoViewController,
                let index = tableView.indexPathForSelectedRow?.row {
                destination.convo = convos[index]
                destination.hidesBottomBarWhenPushed = true
            }
        default:
            return
        }
    }
    
    func showNewConvo(convo: Convo) {
        self.convo = convo
        showConvo = true
    }
}