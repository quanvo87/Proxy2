//
//  HomeViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/25/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase
import FirebaseAuth

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let api = API.sharedInstance
    private var unreadMessages = 0
    
    @IBOutlet weak var homeTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if let user = user {
                self.api.uid = user.uid
            } else {
                let logInViewController  = self.storyboard!.instantiateViewControllerWithIdentifier("Log In View Controller") as! LogInViewController
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                appDelegate.window?.rootViewController = logInViewController
            }
        }
        
        setUpTableView()
        configureDataBase()
    }
    
    override func viewDidAppear(animated: Bool) {
        navigationItem.title = "Conversations (\(unreadMessages))"
    }
    
    override func viewWillDisappear(animated: Bool) {
        var title = ""
        if unreadMessages > 0 {
            title = "(\(unreadMessages))"
        }
        navigationItem.title = title
    }
    
    //    deinit {
    //        ref.child("users").child(api.uid).child("proxies").child(proxyKey).child("coversations").removeObserverWithHandle(conversationsReferenceHandle)
    //        ref.child("users").child(api.uid).child("proxies").child(proxyKey).child("invites").removeObserverWithHandle(invitesReferenceHandle)
    //    }
    
    func configureDataBase() {
        // also need observer to total user unread messages
        
        //        conversationsReferenceHandle = ref.child("users").child(api.uid).child("proxies").child(proxyKey).child("conversations").queryOrderedByChild("lastEventTime").observeEventType(.Value, withBlock: { snapshot in
        //            var newData = [Conversation]()
        //            for item in snapshot.children {
        //                let conversation = Conversation()
        //                newData.append(conversation)
        //            }
        //            self.conversations = newData
        //            self.tableView.reloadData()
        //        })
        
        //        invitesReferenceHandle = ref.child("users").child(api.uid).child("proxies").child(proxyKey).child("invites").queryOrderedByChild("lastEventTime").observeEventType(.Value, withBlock: { snapshot in
        //            var newData = [Invite]()
        //            for item in snapshot.children {
        //                let invite = Invite()
        //                newData.append(invite)
        //            }
        //            self.invites = newData
        //            self.tableView.reloadData()
        //        })
    }
    
    func setUpTableView() {
        automaticallyAdjustsScrollViewInsets = false
        homeTableView.dataSource = self
        homeTableView.delegate = self
        homeTableView.rowHeight = UITableViewAutomaticDimension
        homeTableView.estimatedRowHeight = 80
    }
    
    // MARK: - Table view data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Proxy Table View Cell", forIndexPath: indexPath) as! ProxyTableViewCell
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
}