//
//  ProxyInfoTableViewController.swift
//  proxy
//
//  Created by Quan Vo on 9/1/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class ProxyInfoTableViewController: UITableViewController, NewMessageViewControllerDelegate {
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var proxy = Proxy()
    
    var unreadRef = FIRDatabaseReference()
    var unreadRefHandle = FIRDatabaseHandle()
    
    var convosRef = FIRDatabaseReference()
    var convosRefHandle = FIRDatabaseHandle()
    var convos = [Convo]()
    
    var convo: Convo?
    var shouldShowNewConvo = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let newMessageButton = UIButton(type: .Custom)
        newMessageButton.addTarget(self, action: #selector(ProxyInfoTableViewController.showNewMessageViewController), forControlEvents: UIControlEvents.TouchUpInside)
        newMessageButton.frame = CGRectMake(0, 0, 25, 25)
        newMessageButton.setImage(UIImage(named: "new-message.png"), forState: UIControlState.Normal)
        let newMessageBarButton = UIBarButtonItem(customView: newMessageButton)
        
        let deleteProxyButton = UIButton(type: .Custom)
        deleteProxyButton.addTarget(self, action: #selector(ProxyInfoTableViewController.showDeleteProxyAlert), forControlEvents: UIControlEvents.TouchUpInside)
        deleteProxyButton.frame = CGRectMake(0, 0, 25, 25)
        deleteProxyButton.setImage(UIImage(named: "delete.png"), forState: UIControlState.Normal)
        let deleteProxyBarButton = UIBarButtonItem(customView: deleteProxyButton)
        
        navigationItem.rightBarButtonItems = [newMessageBarButton, deleteProxyBarButton]
        
        for case let scrollView as UIScrollView in tableView.subviews {
            scrollView.delaysContentTouches = false
        }
        tableView.delaysContentTouches = false
        tableView.separatorStyle = .None
        
        unreadRef = ref.child(Path.Proxies).child(proxy.ownerId).child(proxy.key).child(Path.Unread)
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { (snapshot) in
            guard let unread = snapshot.value as? Int else { return }
            self.navigationItem.title = unread.toTitleSuffix()
        })
        
        convosRef = ref.child(Path.Convos).child(proxy.key)
        convosRefHandle = convosRef.queryOrderedByChild(Path.Timestamp).observeEventType(.Value, withBlock: { (snapshot) in
            self.convos = self.api.getConvos(fromSnapshot: snapshot)
            self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        if convo != nil {
            ref.child(Path.Convos).child(convo!.senderId).child(convo!.key).child(Path.SenderLeftConvo).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                if let deleted = snapshot.value as? Bool where deleted {
                    self.navigationController?.popViewControllerAnimated(true)
                }
            })
        }
        
        if shouldShowNewConvo {
            let dest = self.storyboard!.instantiateViewControllerWithIdentifier(Identifiers.ConvoViewController) as! ConvoViewController
            dest.convo = convo!
            shouldShowNewConvo = false
            self.navigationController!.pushViewController(dest, animated: true)
        }
    }
    
    deinit {
        convosRef.removeObserverWithHandle(convosRefHandle)
        unreadRef.removeObserverWithHandle(unreadRefHandle)
    }
    
    func showNewMessageViewController() {
        let dest = storyboard?.instantiateViewControllerWithIdentifier(Identifiers.NewMessageViewController) as! NewMessageViewController
        dest.newMessageViewControllerDelegate = self
        dest.sender = proxy
        navigationController?.pushViewController(dest, animated: true)
    }
    
    func showDeleteProxyAlert() {
        let alert = UIAlertController(title: "Delete Proxy?", message: "You will not be able to see this proxy or its conversations again. Other users will not be notified.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { (void) in
            self.api.delete(proxy: self.proxy, withConvos: self.convos)
            self.navigationController?.popViewControllerAnimated(true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showIconPickerViewController() {
        let dest = self.storyboard?.instantiateViewControllerWithIdentifier(Identifiers.IconPickerCollectionViewController) as! IconPickerCollectionViewController
        dest.convos = convos
        dest.proxy = proxy
        self.navigationController?.pushViewController(dest, animated: true)
    }
    
    func showEditNicknameAlert() {
        let alert = UIAlertController(title: "Edit Nickname", message: "Only you see your nickname.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            textField.autocapitalizationType = .Sentences
            textField.autocorrectionType = .Yes
            textField.clearButtonMode = .WhileEditing
            textField.placeholder = "Enter A Nickname"
            textField.text = self.proxy.nickname
        })
        alert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action) -> Void in
            let nickname = alert.textFields![0].text
            let trim = nickname!.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " "))
            if !(nickname != "" && trim == "") {
                self.api.set(nickname: nickname!, forProxy: self.proxy)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Table view delegate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return convos.count
        default: return 0
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0: return CGFloat.min
        case 1: return 15
        default: return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return "CONVERSATIONS"
        default: return nil
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return 140
        case 1: return 80
        default: return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 1:
            if convos.count == 0 {
                return "No conversations yet. Start one with the 'New Message' button on the top right!"
            } else {
                return nil
            }
        default: return nil
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            let dest = self.storyboard?.instantiateViewControllerWithIdentifier(Identifiers.ConvoViewController) as! ConvoViewController
            dest.convo = convos[tableView.indexPathForSelectedRow!.row]
            navigationController?.pushViewController(dest, animated: true)
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        
        // Proxy info
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.SenderProxyInfoCell, forIndexPath: indexPath) as! SenderProxyInfoCell
            cell.changeIconButton.addTarget(self, action: #selector(ProxyInfoTableViewController.showIconPickerViewController), forControlEvents: .TouchUpInside)
            cell.nicknameButton.addTarget(self, action: #selector(ProxyInfoTableViewController.showEditNicknameAlert), forControlEvents: .TouchUpInside)
            cell.selectionStyle = .None
            return cell
            
        // This proxy's convos
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.ConvoCell, forIndexPath: indexPath) as! ConvoCell
            let convo = convos[indexPath.row]
            
            // Set icon
            cell.iconImageView.image = nil
            cell.iconImageView.kf_indicatorType = .Activity
            api.getURL(forIcon: convo.icon) { (url) in
                guard let url = url else { return }
                cell.iconImageView.kf_setImageWithURL(url, placeholderImage: nil)
            }
            
            // Set labels
            cell.titleLabel.attributedText = api.getConvoTitle(receiverNickname: convo.receiverNickname, receiverName: convo.receiverProxy, senderNickname: convo.senderNickname, senderName: convo.senderProxy)
            cell.lastMessageLabel.text = convo.message
            cell.timestampLabel.text = convo.timestamp.toTimeAgo()
            cell.unreadLabel.text = convo.unread.toNumberLabel()
            
            return cell
            
        default: break
        }
        return UITableViewCell()
    }
    
    // MARK: - Select proxy view controller delegate
    func goToNewConvo(convo: Convo) {
        self.convo = convo
        shouldShowNewConvo = true
    }
}
