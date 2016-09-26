//
//  ProxiesTableViewController.swift
//  proxy
//
//  Created by Quan Vo on 9/10/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class ProxiesTableViewController: UITableViewController, NewMessageViewControllerDelegate {
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    
    var unreadRef = FIRDatabaseReference()
    var unreadRefHandle = FIRDatabaseHandle()
    
    var proxiesRef = FIRDatabaseReference()
    var proxiesRefHandle = FIRDatabaseHandle()
    var proxies = [Proxy]()
    var proxiesToDelete = [Proxy]()
    
    var convo = Convo()
    var shouldShowNewConvo = false
    
    var newMessageButton = UIBarButtonItem()
    var newProxyButton = UIBarButtonItem()
    var deleteProxiesButton = UIBarButtonItem()
    var confirmDeleteProxiesButton = UIBarButtonItem()
    var cancelDeleteProxiesButton = UIBarButtonItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        observeUnread()
        
        // In case user creates a proxy from the Home VC, scroll this VC to top
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ProxiesTableViewController.scrollToTop), name: Notifications.CreatedNewProxyFromHomeTab, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        observeProxies()
        showNewConvo()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        proxiesRef.removeObserverWithHandle(proxiesRefHandle)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        unreadRef.removeObserverWithHandle(unreadRefHandle)
    }
    
    // MARK: - Set up
    func setUp() {
        navigationItem.title = "Proxies"
        newMessageButton = createNewMessageButton()
        newProxyButton = createNewProxyButton()
        deleteProxiesButton = createDeleteProxiesButton()
        confirmDeleteProxiesButton = createConfirmDeleteProxiesButton()
        cancelDeleteProxiesButton = createCancelDeleteProxiesButton()
        setDefaultButtons()
        tableView.rowHeight = 80
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .None
        tableView.allowsMultipleSelectionDuringEditing = true
        unreadRef = ref.child(Path.Unread).child(api.uid)
        proxiesRef = ref.child(Path.Proxies).child(api.uid)
    }
    
    func createNewMessageButton() -> UIBarButtonItem {
        let newMessageButton = UIButton(type: .Custom)
        newMessageButton.setImage(UIImage(named: "new-message.png"), forState: UIControlState.Normal)
        newMessageButton.addTarget(self, action: #selector(ProxiesTableViewController.showNewMessageViewController), forControlEvents: UIControlEvents.TouchUpInside)
        newMessageButton.frame = CGRectMake(0, 0, 25, 25)
        return UIBarButtonItem(customView: newMessageButton)
    }
    
    func createNewProxyButton() -> UIBarButtonItem {
        let newProxyButton = UIButton(type: .Custom)
        newProxyButton.setImage(UIImage(named: "new-proxy.png"), forState: UIControlState.Normal)
        newProxyButton.addTarget(self, action: #selector(ProxiesTableViewController.createNewProxy), forControlEvents: UIControlEvents.TouchUpInside)
        newProxyButton.frame = CGRectMake(0, 0, 25, 25)
        return UIBarButtonItem(customView: newProxyButton)
    }
    
    func createDeleteProxiesButton() -> UIBarButtonItem {
        let deleteProxiesButton = UIButton(type: .Custom)
        deleteProxiesButton.setImage(UIImage(named: "delete.png"), forState: UIControlState.Normal)
        deleteProxiesButton.addTarget(self, action: #selector(ProxiesTableViewController.toggleEditMode), forControlEvents: UIControlEvents.TouchUpInside)
        deleteProxiesButton.frame = CGRectMake(0, 0, 25, 25)
        return UIBarButtonItem(customView: deleteProxiesButton)
    }
    
    func createConfirmDeleteProxiesButton() -> UIBarButtonItem {
        let confirmDeleteProxiesButton = UIButton(type: .Custom)
        confirmDeleteProxiesButton.setImage(UIImage(named: "confirm"), forState: UIControlState.Normal)
        confirmDeleteProxiesButton.addTarget(self, action: #selector(ProxiesTableViewController.deleteSelectedProxies), forControlEvents: UIControlEvents.TouchUpInside)
        confirmDeleteProxiesButton.frame = CGRectMake(0, 0, 25, 25)
        return UIBarButtonItem(customView: confirmDeleteProxiesButton)
    }
    
    func createCancelDeleteProxiesButton() -> UIBarButtonItem {
        let cancelDeleteProxiesButton = UIButton(type: .Custom)
        cancelDeleteProxiesButton.setImage(UIImage(named: "cancel"), forState: UIControlState.Normal)
        cancelDeleteProxiesButton.addTarget(self, action: #selector(ProxiesTableViewController.toggleEditMode), forControlEvents: UIControlEvents.TouchUpInside)
        cancelDeleteProxiesButton.frame = CGRectMake(0, 0, 25, 25)
        return UIBarButtonItem(customView: cancelDeleteProxiesButton)
    }
    
    func setDefaultButtons() {
        navigationItem.leftBarButtonItem = deleteProxiesButton
        navigationItem.rightBarButtonItems = [newMessageButton, newProxyButton]
    }
    
    func setEditModeButtons() {
        navigationItem.leftBarButtonItem = cancelDeleteProxiesButton
        navigationItem.rightBarButtonItems = [confirmDeleteProxiesButton]
    }
    
    func toggleEditMode() {
        tableView.setEditing(!tableView.editing, animated: true)
        if tableView.editing {
            setEditModeButtons()
        } else {
            setDefaultButtons()
            proxiesToDelete = []
        }
    }
    
    func deleteSelectedProxies() {
        tableView.setEditing(false, animated: true)
        setDefaultButtons()
        for proxy in proxiesToDelete {
            api.delete(proxy: proxy)
        }
        proxiesToDelete = []
    }
    
    func createNewProxy() {
        navigationItem.rightBarButtonItems![1].enabled = false
        api.create { (proxy) in
            self.scrollToTop()
            self.navigationItem.rightBarButtonItems![1].enabled = true
        }
    }
    
    func scrollToTop() {
        self.tableView.setContentOffset(CGPointMake(0, -self.tableView.contentInset.top), animated: true)
    }
    
    // MARK: - Database
    // Observe unread for the user to keep the title updated.
    func observeUnread() {
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { (snapshot) in
            self.api.getUnread(forProxies: snapshot, completion: { (unread) in
                self.navigationItem.title = "Proxies \(unread.toTitleSuffix())"
            })
        })
    }
    
    // Observe proxies for this user to display in this VC.
    func observeProxies() {
        proxiesRefHandle = proxiesRef.queryOrderedByChild(Path.Timestamp).observeEventType(.Value, withBlock: { snapshot in
            var proxies = [Proxy]()
            for child in snapshot.children {
                let proxy = Proxy(anyObject: child.value)
                if !proxy.isDeleted {
                    proxies.append(proxy)
                }
            }
            self.proxies = proxies.reverse()
            self.tableView.reloadData()
        })
    }
    
    // MARK: - Table view delegate
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proxies.count
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.min
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !tableView.editing {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            showProxyInfoTableViewController(proxies[indexPath.row])
        } else {
            proxiesToDelete.append(proxies[indexPath.row])
        }
    }
    
    // MARK: - Table view data source
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.ProxyCell, forIndexPath: indexPath) as! ProxyCell
        cell.proxy = proxies[indexPath.row]
        return cell
    }
    
    // MARK: - Select proxy view controller delegate
    func showNewConvo(convo: Convo) {
        self.convo = convo
        shouldShowNewConvo = true
    }
    
    func showNewConvo() {
        if shouldShowNewConvo {
            let dest = self.storyboard!.instantiateViewControllerWithIdentifier(Identifiers.ConvoViewController) as! ConvoViewController
            dest.convo = convo
            shouldShowNewConvo = false
            self.navigationController!.pushViewController(dest, animated: true)
        }
    }
    
    // MARK: - Navigation
    func showNewMessageViewController() {
        let dest = storyboard!.instantiateViewControllerWithIdentifier(Identifiers.NewMessageViewController) as! NewMessageViewController
        dest.delegate = self
        navigationController?.pushViewController(dest, animated: true)
    }
    
    func showProxyInfoTableViewController(proxy: Proxy) {
        let dest = storyboard?.instantiateViewControllerWithIdentifier(Identifiers.ProxyInfoTableViewController) as! ProxyInfoTableViewController
        dest.proxy = proxy
        navigationController?.pushViewController(dest, animated: true)
    }
}
