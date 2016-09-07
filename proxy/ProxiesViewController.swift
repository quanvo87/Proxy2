//
//  ProxiesViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class ProxiesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NewMessageViewControllerDelegate {
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var proxiesRef = FIRDatabaseReference()
    var unreadRef = FIRDatabaseReference()
    var proxiesRefHandle = FIRDatabaseHandle()
    var unreadRefHandle = FIRDatabaseHandle()
    var proxies = [Proxy]()
    var convo = Convo()
    var shouldShowConvo = false
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
        observeUnread()
        setUpTableView()
        observeProxies()
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
        proxiesRef.removeObserverWithHandle(proxiesRefHandle)
        unreadRef.removeObserverWithHandle(unreadRefHandle)
    }
    
    func setUpUI() {
        self.navigationItem.title = "Proxies"
        addNavBarButtons()
    }
    
    func addNavBarButtons() {
        // New Message Button
        let newMessageButton = UIButton(type: .Custom)
        newMessageButton.setImage(UIImage(named: "new-message.png"), forState: UIControlState.Normal)
        newMessageButton.addTarget(self, action: #selector(ProxiesViewController.tapNewMessageButton), forControlEvents: UIControlEvents.TouchUpInside)
        newMessageButton.frame = CGRectMake(0, 0, 25, 25)
        let newMessageBarButton = UIBarButtonItem(customView: newMessageButton)
        
        // New Proxy Button
        let newProxyButton = UIButton(type: .Custom)
        newProxyButton.setImage(UIImage(named: "new-proxy.png"), forState: UIControlState.Normal)
        newProxyButton.addTarget(self, action: #selector(ProxiesViewController.tapNewProxyButton), forControlEvents: UIControlEvents.TouchUpInside)
        newProxyButton.frame = CGRectMake(0, 0, 25, 25)
        let newProxyBarButton = UIBarButtonItem(customView: newProxyButton)
        
        self.navigationItem.rightBarButtonItems = [newMessageBarButton, newProxyBarButton]
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
        proxiesRefHandle = proxiesRef.queryOrderedByChild("name").observeEventType(.Value, withBlock: { snapshot in
            var proxies = [Proxy]()
            for child in snapshot.children {
                let proxy = Proxy(anyObject: child.value)
                proxies.append(proxy)
            }
            self.proxies = proxies
            self.tableView.reloadData()
        })
    }
    
    func setUpTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        automaticallyAdjustsScrollViewInsets = false
        tableView.rowHeight = 60
        tableView.estimatedRowHeight = 60
        tableView.separatorStyle = .None
    }
    
    // MARK: - Table view delegate
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proxies.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - Table view data source
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Identifiers.ProxyCell, forIndexPath: indexPath) as! ProxyCell
        let proxy = self.proxies[indexPath.row]

        if let iconURL = self.api.iconURLCache[proxy.icon] {
            cell.iconImage.kf_setImageWithURL(NSURL(string: iconURL), placeholderImage: nil)
        } else {
            let storageRef = FIRStorage.storage().referenceForURL(Constants.URLs.Storage)
            let starsRef = storageRef.child("\(proxy.icon).png")
            starsRef.downloadURLWithCompletion { (URL, error) -> Void in
                if error == nil {
                    self.api.iconURLCache[proxy.icon] = URL?.absoluteString
                    cell.iconImage.kf_setImageWithURL(NSURL(string: URL!.absoluteString)!, placeholderImage: nil)
                }
            }
        }
        
        cell.titleLabel.text = proxy.name
        cell.subtitleLabel.attributedText = proxy.nickname.nicknameFormatted()
        cell.accessoryType = .None
        return cell
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
        if segue.identifier == Constants.Segues.ProxySegue,
            let dest = segue.destinationViewController as? ProxyInfoTableViewController,
            index = tableView.indexPathForSelectedRow?.row {
            dest.proxy = proxies[index]
        }
    }
}