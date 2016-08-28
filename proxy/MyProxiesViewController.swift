//
//  MyProxiesViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase

class MyProxiesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let api = API.sharedInstance
    private let ref = FIRDatabase.database().reference()
    private var proxiesRef = FIRDatabaseReference()
    private var unreadRef = FIRDatabaseReference()
    private var proxiesRefHandle = FIRDatabaseHandle()
    private var unreadRefHandle = FIRDatabaseHandle()
    private var proxies = [FIRDataSnapshot]()
    private var unread = 0
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpTableView()
        configureDatabase()
    }
    
    override func viewWillAppear(animated: Bool) {
        setTitle()
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationItem.title = unread.titleSuffixFromUnreadMessageCount()
    }
    
    deinit {
        proxiesRef.removeObserverWithHandle(proxiesRefHandle)
        unreadRef.removeObserverWithHandle(unreadRefHandle)
    }
    
    func setTitle() {
        navigationItem.title = "My Proxies \(unread.titleSuffixFromUnreadMessageCount())"
    }
    
    func configureDatabase() {
        proxiesRef = ref.child("users").child(api.uid).child("proxies")
        proxiesRefHandle = proxiesRef.queryOrderedByChild(Constants.ProxyFields.Timestamp).observeEventType(.Value, withBlock: { snapshot in
            var _proxies = [FIRDataSnapshot]()
            for child in snapshot.children {
                _proxies.append(child as! FIRDataSnapshot)
            }
            self.proxies = _proxies
            self.tableView.reloadData()
        })
        
        unreadRef = ref.child("users").child(api.uid).child(Constants.ProxyFields.Unread)
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { snapshot in
            self.unread = snapshot.value as! Int
            self.setTitle()
        })
    }
    
    // MARK: - Table view
    
    func setUpTableView() {
        automaticallyAdjustsScrollViewInsets = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proxies.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Identifiers.ProxyTableViewCell, forIndexPath: indexPath) as! ProxyTableViewCell
        
        let proxy = self.proxies[indexPath.row].value as! [String: AnyObject]
        
        var name = ""
        var nickname = ""
        var lastMessage = ""
        var timestamp = 0.0
        var unreadMessageCount = 0
        
        if let _name = proxy[Constants.ProxyFields.Name] {
            name = _name as! String
        }
        if let _nickname = proxy[Constants.ProxyFields.Nickname] {
            nickname = _nickname as! String
        }
        if let _timestamp = proxy[Constants.ProxyFields.Timestamp] {
            timestamp = _timestamp as! Double
        }
        if let _lastMessage = proxy[Constants.ProxyFields.Message] {
            lastMessage = _lastMessage as! String
        }
        if let _unreadMessageCount = proxy[Constants.ProxyFields.Unread] {
            unreadMessageCount = _unreadMessageCount as! Int
        }
        
        cell.nameLabel.text = name
        cell.nicknameLabel.text = nickname.nicknameFormattedWithDash()
        cell.timestampLabel.text = timestamp.timeAgoFromTimeInterval()
        cell.lastMessagePreviewLabel.text = lastMessage.lastMessageWithTimestamp(timestamp)
        cell.unreadMessageCountLabel.text = unreadMessageCount.unreadMessageCountFormatted()
        
        return cell
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.Segues.ProxyDetailSegue,
            let destination = segue.destinationViewController as? ProxyDetailViewController,
            index = tableView.indexPathForSelectedRow?.row {
            destination.proxy = proxies[index].value as! [String: AnyObject]
        }
    }
}