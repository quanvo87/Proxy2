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
    let ref = Database.database().reference()
    
    var newMessageBarButton = UIBarButtonItem()
    var newProxyBarButton = UIBarButtonItem()
    var deleteProxiesBarButton = UIBarButtonItem()
    var confirmDeleteProxiesBarButton = UIBarButtonItem()
    var cancelDeleteProxiesBarButton = UIBarButtonItem()
    
    var unreadRef = DatabaseReference()
    var unreadRefHandle = DatabaseHandle()
    
    var proxiesRef = DatabaseReference()
    var proxiesRefHandle = DatabaseHandle()
    var proxies = [Proxy]()
    var proxiesToDelete = [Proxy]()
    
    var convo = Convo()
    var shouldShowNewConvo = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Proxies"
        
        let newMessageButton = UIButton(type: .custom)
        newMessageButton.addTarget(self, action: #selector(ProxiesTableViewController.showNewMessageViewController), for: UIControlEvents.touchUpInside)
        newMessageButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        newMessageButton.setImage(UIImage(named: "new-message.png"), for: UIControlState.normal)
        newMessageBarButton = UIBarButtonItem(customView: newMessageButton)
        
        let newProxyButton = UIButton(type: .custom)
        newProxyButton.addTarget(self, action: #selector(ProxiesTableViewController.createNewProxy), for: UIControlEvents.touchUpInside)
        newProxyButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        newProxyButton.setImage(UIImage(named: "new-proxy.png"), for: UIControlState.normal)
        newProxyBarButton = UIBarButtonItem(customView: newProxyButton)
        
        let deleteProxiesButton = UIButton(type: .custom)
        deleteProxiesButton.addTarget(self, action: #selector(ProxiesTableViewController.toggleEditMode), for: UIControlEvents.touchUpInside)
        deleteProxiesButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        deleteProxiesButton.setImage(UIImage(named: "delete.png"), for: UIControlState.normal)
        deleteProxiesBarButton = UIBarButtonItem(customView: deleteProxiesButton)
        
        let confirmDeleteProxiesButton = UIButton(type: .custom)
        confirmDeleteProxiesButton.addTarget(self, action: #selector(ProxiesTableViewController.confirmDeleteProxies), for: UIControlEvents.touchUpInside)
        confirmDeleteProxiesButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        confirmDeleteProxiesButton.setImage(UIImage(named: "confirm"), for: UIControlState.normal)
        confirmDeleteProxiesBarButton = UIBarButtonItem(customView: confirmDeleteProxiesButton)
        
        let cancelDeleteProxiesButton = UIButton(type: .custom)
        cancelDeleteProxiesButton.addTarget(self, action: #selector(ProxiesTableViewController.toggleEditMode), for: UIControlEvents.touchUpInside)
        cancelDeleteProxiesButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        cancelDeleteProxiesButton.setImage(UIImage(named: "cancel"), for: UIControlState.normal)
        cancelDeleteProxiesBarButton = UIBarButtonItem(customView: cancelDeleteProxiesButton)
        
        setDefaultButtons()
        
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
        
        unreadRef = ref.child(Path.Unread).child(api.uid).child(Path.Unread)
        unreadRefHandle = unreadRef.observe(.value, with: { (snapshot) in
            if let unread = snapshot.value as? Int {
                self.navigationItem.title = "Proxies" + unread.asLabelWithParens
            } else {
                self.navigationItem.title = "Proxies"
            }
        })
        
        proxiesRef = ref.child(Path.Proxies).child(api.uid)
        proxiesRefHandle = proxiesRef.queryOrdered(byChild: Path.Timestamp).observe(.value, with: { snapshot in
            var proxies = [Proxy]()
            for child in snapshot.children {
                if let proxy = Proxy((child as! DataSnapshot).value as AnyObject) {
                    proxies.append(proxy)
                }
            }
            self.proxies = proxies.reversed()
            self.tableView.visibleCells.incrementedTags
            self.tableView.reloadData()
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(ProxiesTableViewController.scrollToTop), name: NSNotification.Name(rawValue: Notifications.CreatedNewProxyFromHomeTab), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        showNewConvo()
        tableView.reloadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        unreadRef.removeObserver(withHandle: unreadRefHandle)
        proxiesRef.removeObserver(withHandle: proxiesRefHandle)
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
        tableView.setEditing(!tableView.isEditing, animated: true)
        if tableView.isEditing {
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
            api.deleteProxy(proxy)
        }
        proxiesToDelete = []
    }
    
    func confirmDeleteProxies() {
        guard !proxiesToDelete.isEmpty else {
            toggleEditMode()
            return
        }
        let alert = UIAlertController(title: "Delete Proxies?", message: "You will not be able to view their conversations anymore.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
            self.deleteSelectedProxies()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func createNewProxy() {
        navigationItem.rightBarButtonItems![1].isEnabled = false
        api.createProxy { (proxy) in
            self.navigationItem.rightBarButtonItems![1].isEnabled = true
            guard proxy != nil else {
                self.showAlert("Proxy Limit Reached", message: "Cannot exceed 50 proxies. Delete some old ones, then try again!")
                return
            }
            self.scrollToTop()
        }
    }
    
    func scrollToTop() {
        self.tableView.setContentOffset(CGPoint(x: 0, y: -self.tableView.contentInset.top), animated: true)
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proxies.count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !tableView.isEditing {
            tableView.deselectRow(at: indexPath, animated: true)
            showProxyInfoTableViewController(proxies[indexPath.row])
        } else {
            proxiesToDelete.append(proxies[indexPath.row])
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        var index = 0
        let proxy = proxies[indexPath.row]
        for _proxy in proxiesToDelete {
            if _proxy.key == proxy.key {
                proxiesToDelete.remove(at: index)
                return
            }
            index += 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.ProxyCell, for: indexPath as IndexPath) as! ProxyCell
        let proxy = proxies[indexPath.row]
        
        // 'New' image
        cell.newImageView.isHidden = true
        let secondsAgo = -Date(timeIntervalSince1970: proxy.created).timeIntervalSinceNow
        if secondsAgo < 60 * Settings.NewProxyIndicatorDuration {
            cell.newImageView.isHidden = false
        }
        cell.contentView.bringSubview(toFront: cell.newImageView)
        
        // Icon
        cell.iconImageView.image = nil
        DBIcon.getImageForIcon(proxy.icon + ".png" as AnyObject, tag: cell.tag) { (image, tag) in
            guard tag == cell.tag else { return }
            guard let image = image else {
                return
            }
            cell.iconImageView.image = image
        }
        
        // Labels
        cell.nameLabel.text = proxy.name
        cell.nicknameLabel.text = proxy.nickname
        cell.convoCountLabel.text = proxy.convos.asLabel
        cell.unreadLabel.text = proxy.unread.asLabel
        
        return cell
    }
    
    // MARK: - Select proxy view controller delegate
    func goToNewConvo(_ convo: Convo) {
        self.convo = convo
        shouldShowNewConvo = true
    }
    
    func showNewConvo() {
        if shouldShowNewConvo {
            let dest = self.storyboard!.instantiateViewController(withIdentifier: Identifiers.ConvoViewController) as! ConvoViewController
            dest.convo = convo
            shouldShowNewConvo = false
            self.navigationController!.pushViewController(dest, animated: true)
        }
    }
    
    // MARK: - Navigation
    func showNewMessageViewController() {
        let dest = storyboard!.instantiateViewController(withIdentifier: Identifiers.NewMessageViewController) as! NewMessageViewController
        dest.newMessageViewControllerDelegate = self
        navigationController?.pushViewController(dest, animated: true)
    }
    
    func showProxyInfoTableViewController(_ proxy: Proxy) {
        let dest = storyboard?.instantiateViewController(withIdentifier: Identifiers.ProxyInfoTableViewController) as! ProxyInfoTableViewController
        dest.proxy = proxy
        navigationController?.pushViewController(dest, animated: true)
    }
}
