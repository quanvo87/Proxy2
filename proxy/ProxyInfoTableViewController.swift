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
    
    var nicknameRef = FIRDatabaseReference()
    var nicknameRefHandle = FIRDatabaseHandle()
    var nickname = ""
    
    var convosRef = FIRDatabaseReference()
    var convosRefHandle = FIRDatabaseHandle()
    var convos = [Convo]()
    
    var convo = Convo()
    var shouldShowNewConvo = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        observeUnread()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        showNewConvo()
        observeConvos()
        observeNickname()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        nicknameRef.removeObserverWithHandle(nicknameRefHandle)
        convosRef.removeObserverWithHandle(convosRefHandle)
    }
    
    deinit {
        unreadRef.removeObserverWithHandle(unreadRefHandle)
    }
    
    // MARK: - Set up
    func setUp() {
        addNavBarButtons()
        tableView.separatorStyle = .None
        
        // So buttons inside cells detect touches immediately (there's a delay on by default)
        tableView.delaysContentTouches = false
        for case let scrollView as UIScrollView in tableView.subviews {
            scrollView.delaysContentTouches = false
        }
        
        unreadRef = ref.child(Path.Unread).child(api.uid).child(proxy.key)
        nicknameRef = ref.child(Path.Nickname).child(proxy.key).child(Path.Nickname)
        convosRef = ref.child(Path.Convos).child(proxy.key)
    }
    
    func addNavBarButtons() {
        let newMessageButton = UIButton(type: .Custom)
        newMessageButton.setImage(UIImage(named: "new-message.png"), forState: UIControlState.Normal)
        newMessageButton.addTarget(self, action: #selector(ProxyInfoTableViewController.showNewMessageViewController), forControlEvents: UIControlEvents.TouchUpInside)
        newMessageButton.frame = CGRectMake(0, 0, 25, 25)
        let newMessageBarButton = UIBarButtonItem(customView: newMessageButton)
        
        let deleteProxyButton = UIButton(type: .Custom)
        deleteProxyButton.setImage(UIImage(named: "delete.png"), forState: UIControlState.Normal)
        deleteProxyButton.addTarget(self, action: #selector(ProxyInfoTableViewController.showDeleteProxyAlert), forControlEvents: UIControlEvents.TouchUpInside)
        deleteProxyButton.frame = CGRectMake(0, 0, 25, 25)
        let deleteProxyBarButton = UIBarButtonItem(customView: deleteProxyButton)
        
        self.navigationItem.rightBarButtonItems = [newMessageBarButton, deleteProxyBarButton]
    }
    
    // Dismiss keyboard when scroll table view down
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    // MARK: - Database
    func observeUnread() {
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { (snapshot) in
            var unread = 0
            for convo in snapshot.children {
                let convo = convo as! FIRDataSnapshot
                unread += convo.value as! Int
            }
            self.navigationItem.title = unread.toTitleSuffix()
        })
    }
    
    func observeNickname() {
        nicknameRefHandle = nicknameRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let nickname = snapshot.value as? String {
                self.nickname = nickname
            }
        })
    }
    
    func observeConvos() {
        convosRefHandle = convosRef.queryOrderedByChild(Path.Timestamp).observeEventType(.Value, withBlock: { (snapshot) in
            var convos = [Convo]()
            for child in snapshot.children {
                let convo = Convo(anyObject: child.value)
                if !convo.didLeaveConvo {
                    convos.append(convo)
                }
            }
            self.convos = convos.reverse()
            self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
        })
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
            showConvoViewController()
        }
    }
    
    // MARK: - Table view data source
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        
        // Header
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.SenderProxyInfoCell, forIndexPath: indexPath) as! SenderProxyInfoCell
            cell.removeObservers()
            cell.proxy = proxy
            cell.nicknameButton.addTarget(self, action: #selector(ProxyInfoTableViewController.showEditNicknameAlert), forControlEvents: .TouchUpInside)
            cell.changeIconButton.addTarget(self, action: #selector(ProxyInfoTableViewController.showIconPickerViewController), forControlEvents: .TouchUpInside)
            return cell
            
        // This proxy's convos
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.ConvoCell, forIndexPath: indexPath) as! ConvoCell
            cell.convo = convos[indexPath.row]
            return cell
            
        default: break
        }
        return UITableViewCell()
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
    
    func showEditNicknameAlert() {
        let alert = UIAlertController(title: "Edit Nickname", message: "Only you see your nickname.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            textField.autocapitalizationType = .Sentences
            textField.autocorrectionType = .Yes
            textField.clearButtonMode = .WhileEditing
            textField.placeholder = "Enter A Nickname"
            textField.text = self.nickname
        })
        alert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action) -> Void in
            let nickname = alert.textFields![0].text
            let trim = nickname!.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " "))
            if !(nickname != "" && trim == "") {
                self.api.set(nickname: nickname!, forProxy: self.proxy.key)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
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
    // Show VC to choose a new icon for the user's proxy.
    func showIconPickerViewController() {
        let dest = self.storyboard?.instantiateViewControllerWithIdentifier(Identifiers.IconPickerCollectionViewController) as! IconPickerCollectionViewController
        dest.proxy = proxy
        dest.convos = convos
        self.navigationController?.pushViewController(dest, animated: true)
    }
    
    func showConvoViewController() {
        let dest = self.storyboard?.instantiateViewControllerWithIdentifier(Identifiers.ConvoViewController) as! ConvoViewController
        dest.convo = convos[tableView.indexPathForSelectedRow!.row]
        navigationController?.pushViewController(dest, animated: true)
    }
    
    func showNewMessageViewController() {
        let dest = storyboard?.instantiateViewControllerWithIdentifier(Identifiers.NewMessageViewController) as! NewMessageViewController
        dest.proxy = proxy
        dest.delegate = self
        navigationController?.pushViewController(dest, animated: true)
    }
}
