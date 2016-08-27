//
//  MyProxiesViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase

class MyProxiesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let api = API.sharedInstance
    private let ref = FIRDatabase.database().reference()
    private var userProxiesReferenceHandle = FIRDatabaseHandle()
    private var userUnreadMessageCountHandle = FIRDatabaseHandle()
    private var proxies = [FIRDataSnapshot]()
    private var unreadMessages = 0
    
    @IBOutlet weak var myProxiesTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpTableView()
        configureDatabase()
    }
    
    override func viewDidAppear(animated: Bool) {
        setTitle()
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationItem.title = "(\(unreadMessages))"
    }
    
    deinit {
        ref.child("users").child(api.uid).child("proxies").removeObserverWithHandle(userProxiesReferenceHandle)
        ref.child("users").child(api.uid).child("unreadMessageCount").removeObserverWithHandle(userProxiesReferenceHandle)
    }
    
    func setTitle() {
        navigationItem.title = "My Proxies (\(unreadMessages))"
    }
    
    func setUpTableView() {
        automaticallyAdjustsScrollViewInsets = false
        myProxiesTableView.delegate = self
        myProxiesTableView.dataSource = self
        myProxiesTableView.rowHeight = UITableViewAutomaticDimension
        myProxiesTableView.estimatedRowHeight = 80
    }
    
    func configureDatabase() {
        userProxiesReferenceHandle = ref.child("users").child(api.uid).child("proxies").queryOrderedByChild("lastMessageTime").observeEventType(.Value, withBlock: { snapshot in
            var newProxies = [FIRDataSnapshot]()
            for child in snapshot.children {
                newProxies.append(child as! FIRDataSnapshot)
            }
            self.proxies = newProxies
            self.myProxiesTableView.reloadData()
        })
        
        userUnreadMessageCountHandle = ref.child("users").child(api.uid).child("unreadMessageCount").observeEventType(.Value, withBlock: { snapshot in
            self.unreadMessages = snapshot.value as! Int
            self.setTitle()
        })
    }
    
    // MARK: - Table view data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proxies.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Proxy Table View Cell", forIndexPath: indexPath) as! ProxyTableViewCell
        
        let proxySnapshot = self.proxies[indexPath.row]
        let proxy = proxySnapshot.value as! Dictionary<String, AnyObject>

        var name = ""
        var nickname = ""
        var lastMessage = ""
        var timestamp = 0.0
        var unreadMessageCount = 0
        
        if let _name = proxy["name"] {
            name = _name as! String
        }
        if let _nickname = proxy["nickname"] {
            nickname = _nickname as! String
        }
        if let _timestamp = proxy["lastMessageTime"] {
            timestamp = _timestamp as! Double
        }
        if let _lastMessage = proxy["lastMessage"] {
            lastMessage = _lastMessage as! String
        }
        if let _unreadMessageCount = proxy["unreadMessageCount"] {
            unreadMessageCount = _unreadMessageCount as! Int
        }
        
        cell.nameLabel.text = name
        cell.nicknameLabel.text = nickname.nicknameFormatted()
        cell.timestampLabel.text = timestamp.timeAgoFromTimeInterval()
        cell.lastMessagePreviewLabel.text = lastMessage.lastMessageWithTimestamp(timestamp)
        cell.unreadMessageCountLabel.text = unreadMessageCount.unreadMessageCountFormatted()
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
       
    }
}