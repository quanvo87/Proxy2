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
    
    var newMessageBarButton = UIBarButtonItem()
    var newProxyBarButton = UIBarButtonItem()
    var deleteProxiesBarButton = UIBarButtonItem()
    var confirmDeleteProxiesBarButton = UIBarButtonItem()
    var cancelDeleteProxiesBarButton = UIBarButtonItem()
    
    var unreadRef = FIRDatabaseReference()
    var unreadRefHandle = FIRDatabaseHandle()
    
    var proxiesRef = FIRDatabaseReference()
    var proxiesRefHandle = FIRDatabaseHandle()
    var proxies = [Proxy]()
    var proxiesToDelete = [Proxy]()
    
    var convo = Convo()
    var shouldShowNewConvo = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Proxies"
        
        let newMessageButton = UIButton(type: .Custom)
        newMessageButton.addTarget(self, action: #selector(ProxiesTableViewController.showNewMessageViewController), forControlEvents: UIControlEvents.TouchUpInside)
        newMessageButton.frame = CGRectMake(0, 0, 25, 25)
        newMessageButton.setImage(UIImage(named: "new-message.png"), forState: UIControlState.Normal)
        newMessageBarButton = UIBarButtonItem(customView: newMessageButton)
        
        let newProxyButton = UIButton(type: .Custom)
        newProxyButton.addTarget(self, action: #selector(ProxiesTableViewController.createNewProxy), forControlEvents: UIControlEvents.TouchUpInside)
        newProxyButton.frame = CGRectMake(0, 0, 25, 25)
        newProxyButton.setImage(UIImage(named: "new-proxy.png"), forState: UIControlState.Normal)
        newProxyBarButton = UIBarButtonItem(customView: newProxyButton)
        
        let deleteProxiesButton = UIButton(type: .Custom)
        deleteProxiesButton.addTarget(self, action: #selector(ProxiesTableViewController.toggleEditMode), forControlEvents: UIControlEvents.TouchUpInside)
        deleteProxiesButton.frame = CGRectMake(0, 0, 25, 25)
        deleteProxiesButton.setImage(UIImage(named: "delete.png"), forState: UIControlState.Normal)
        deleteProxiesBarButton = UIBarButtonItem(customView: deleteProxiesButton)
        
        let confirmDeleteProxiesButton = UIButton(type: .Custom)
        confirmDeleteProxiesButton.addTarget(self, action: #selector(ProxiesTableViewController.confirmDeleteProxies), forControlEvents: UIControlEvents.TouchUpInside)
        confirmDeleteProxiesButton.frame = CGRectMake(0, 0, 25, 25)
        confirmDeleteProxiesButton.setImage(UIImage(named: "confirm"), forState: UIControlState.Normal)
        confirmDeleteProxiesBarButton = UIBarButtonItem(customView: confirmDeleteProxiesButton)
        
        let cancelDeleteProxiesButton = UIButton(type: .Custom)
        cancelDeleteProxiesButton.addTarget(self, action: #selector(ProxiesTableViewController.toggleEditMode), forControlEvents: UIControlEvents.TouchUpInside)
        cancelDeleteProxiesButton.frame = CGRectMake(0, 0, 25, 25)
        cancelDeleteProxiesButton.setImage(UIImage(named: "cancel"), forState: UIControlState.Normal)
        cancelDeleteProxiesBarButton = UIBarButtonItem(customView: cancelDeleteProxiesButton)
        
        setDefaultButtons()
        
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.rowHeight = 60
        tableView.separatorStyle = .None
        
        unreadRef = ref.child(Path.Unread).child(api.uid).child(Path.Unread)
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let unread = snapshot.value as? Int {
                self.navigationItem.title = "Proxies \(unread.toTitleSuffix())"
            } else {
                self.navigationItem.title = "Proxies"
            }
        })
        
        proxiesRef = ref.child(Path.Proxies).child(api.uid)
        proxiesRefHandle = proxiesRef.queryOrderedByChild(Path.Timestamp).observeEventType(.Value, withBlock: { snapshot in
            var proxies = [Proxy]()
            for child in snapshot.children {
                let proxy = Proxy(anyObject: child.value)
                proxies.append(proxy)
            }
            self.proxies = proxies.reverse()
            self.tableView.reloadData()
        })
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ProxiesTableViewController.scrollToTop), name: Notifications.CreatedNewProxyFromHomeTab, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        showNewConvo()
        tableView.reloadData()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        unreadRef.removeObserverWithHandle(unreadRefHandle)
        proxiesRef.removeObserverWithHandle(proxiesRefHandle)
    }
    
    func setDefaultButtons() {
        navigationItem.leftBarButtonItem = deleteProxiesBarButton
        navigationItem.rightBarButtonItems = [newMessageBarButton, newProxyBarButton]
    }
    
    func setEditModeButtons() {
        navigationItem.leftBarButtonItem = cancelDeleteProxiesBarButton
        navigationItem.rightBarButtonItems = [confirmDeleteProxiesBarButton]
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
    
    func confirmDeleteProxies() {
        guard !proxiesToDelete.isEmpty else {
            toggleEditMode()
            return
        }
        let alert = UIAlertController(title: "Delete Proxies?", message: "You will not be able to view their conversations anymore.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { (action) in
            self.deleteSelectedProxies()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func createNewProxy() {
        navigationItem.rightBarButtonItems![1].enabled = false
        api.create { (proxy) in
            self.navigationItem.rightBarButtonItems![1].enabled = true
            guard proxy != nil else {
                self.showAlert("Proxy Limit Reached", message: "Cannot exceed 50 proxies. Delete some old ones, then try again!")
                return
            }
            self.scrollToTop()
        }
    }
    
    func scrollToTop() {
        self.tableView.setContentOffset(CGPointMake(0, -self.tableView.contentInset.top), animated: true)
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
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        var index = 0
        let proxy = proxies[indexPath.row]
        for _proxy in proxiesToDelete {
            if _proxy.key == proxy.key {
                proxiesToDelete.removeAtIndex(index)
                return
            }
            index += 1
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.ProxyCell, forIndexPath: indexPath) as! ProxyCell
        let proxy = proxies[indexPath.row]
        
        // Set 'new' image
        cell.newImageView.hidden = true
        let secondsAgo = -NSDate(timeIntervalSince1970: proxy.created).timeIntervalSinceNow
        if secondsAgo < 60 * Settings.NewProxyIndicatorDuration {
            cell.newImageView.hidden = false
        }
        cell.contentView.bringSubviewToFront(cell.newImageView)
        
        // Set icon
        cell.iconImageView.image = nil
        cell.iconImageView.kf_indicatorType = .Activity
        api.getURL(forIcon: proxy.icon) { (url) in
            guard let url = url else { return }
            cell.iconImageView.kf_setImageWithURL(url, placeholderImage: nil)
        }
        
        // Set labels
        cell.nameLabel.text = proxy.key
        cell.nicknameLabel.text = proxy.nickname
        cell.convoCountLabel.text = proxy.convos.toNumberLabel()
        cell.unreadLabel.text = proxy.unread.toNumberLabel()
        
        return cell
    }
    
    // MARK: - Select proxy view controller delegate
    func goToNewConvo(convo: Convo) {
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
        dest.newMessageViewControllerDelegate = self
        navigationController?.pushViewController(dest, animated: true)
    }
    
    func showProxyInfoTableViewController(proxy: Proxy) {
        let dest = storyboard?.instantiateViewControllerWithIdentifier(Identifiers.ProxyInfoTableViewController) as! ProxyInfoTableViewController
        dest.proxy = proxy
        navigationController?.pushViewController(dest, animated: true)
    }
}
