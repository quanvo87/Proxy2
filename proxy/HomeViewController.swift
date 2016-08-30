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
            // push convo onto nav
            let convoViewController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.Identifiers.ConvoViewController) as! ConvoViewController
            convoViewController.convo = convo
            self.navigationController!.pushViewController(convoViewController, animated: true)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationItem.title = unread.titleSuffixFromUnreadMessageCount()
    }
    
    deinit {
        convosRef.removeObserverWithHandle(convosRefHandle)
        unreadRef.removeObserverWithHandle(unreadRefHandle)
    }
    
    func setTitle() {
        navigationItem.title = "Messages \(unread.titleSuffixFromUnreadMessageCount())"
    }
    
    func configureDatabase() {
        convosRef = ref.child("users").child(api.uid).child("convos")
        convosRefHandle = convosRef.queryOrderedByChild("timestamp").observeEventType(.Value, withBlock: { snapshot in
            var convos = [Convo]()
            var index = -1
            for child in snapshot.children {
                var convo = Convo(anyObject: child.value)
                self.ref.child("unread").child(self.api.uid).queryOrderedByKey().queryEqualToValue(convo.key).observeSingleEventOfType(.Value, withBlock: { snapshot in
                    if let unread = snapshot.value as? [String : Int] {
                        convo.unread = unread[convo.key]! as Int
                        self.convos[index] = convo
                        self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: UITableViewRowAnimation.None)
                    }
                })
                convos.append(convo)
                index += 1
            }
            self.convos = convos.reverse()
            self.tableView.reloadData()
        })
        
        unreadRef = ref.child("users").child(api.uid).child("unread")
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { snapshot in
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
        
        cell.nameLabel.text = convo.nickname.nicknameWithDashBack() + convo.members
        cell.timestampLabel.text = convo.timestamp.timeAgoFromTimeInterval()
        cell.lastMessagePreviewLabel.text = convo.message
        cell.unreadMessageCountLabel.text = convo.unread.unreadMessageCountFormatted()
        
        return cell
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.Segues.NewMessageSegue,
            let destination = segue.destinationViewController as? NewMessageViewController {
            destination.delegate = self
        }
    }
    
    func showNewConvo(convo: Convo) {
        self.convo = convo
        showConvo = true
    }
}