//
//  ProxiesViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase

class ProxiesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let api = API.sharedInstance
    private let ref = FIRDatabase.database().reference()
    private var proxiesRef = FIRDatabaseReference()
    private var unreadRef = FIRDatabaseReference()
    private var proxiesRefHandle = FIRDatabaseHandle()
    private var unreadRefHandle = FIRDatabaseHandle()
    private var proxies = [Proxy]()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Proxies"
        observeUnread()
        setUpTableView()
        observeProxies()
    }
    
    deinit {
        proxiesRef.removeObserverWithHandle(proxiesRefHandle)
        unreadRef.removeObserverWithHandle(unreadRefHandle)
    }
    
    func observeUnread() {
        unreadRef = ref.child("users").child(api.uid).child("unread")
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { snapshot in
            if let unread = snapshot.value as? Int {
                self.navigationItem.title = "Proxies \(unread.unreadTitleSuffix())"
            }
        })
    }
    
    func observeProxies() {
        proxiesRef = ref.child("users").child(api.uid).child("proxies")
        proxiesRefHandle = proxiesRef.queryOrderedByChild("timestamp").observeEventType(.Value, withBlock: { snapshot in
            var proxies = [Proxy]()
            for child in snapshot.children {
                var proxy = Proxy(anyObject: child.value)
                proxy.unread = child.value["unread"] as? Int ?? 0
                proxies.append(proxy)
            }
            self.proxies = proxies.reverse()
            self.tableView.reloadData()
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
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Identifiers.ProxyCell, forIndexPath: indexPath) as! ProxyCell
        let proxy = self.proxies[indexPath.row]
        cell.titleLabel.text = proxy.name
        cell.subtitleLabel.attributedText = proxy.nickname.nicknameFormatted()
        cell.timestampLabel.text = proxy.timestamp.timeAgoFromTimeInterval()
        cell.messageLabel.text = proxy.message.lastMessageWithTimestamp(proxy.timestamp)
        cell.unreadLabel.text = proxy.unread.unreadFormatted()
        return cell
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.Segues.ProxySegue,
            let destination = segue.destinationViewController as? ProxyTableViewController,
            index = tableView.indexPathForSelectedRow?.row {
            destination.proxy = proxies[index]
        }
    }
}