//
//  ProxyInfoTableViewController.swift
//  proxy
//
//  Created by Quan Vo on 9/1/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class ProxyInfoTableViewController: UITableViewController, NewMessageViewControllerDelegate {
    
    var proxy = Proxy()
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var unreadRef = FIRDatabaseReference()
    var unreadRefHandle = FIRDatabaseHandle()
    var convosRef = FIRDatabaseReference()
    var convosRefHandle = FIRDatabaseHandle()
    var nicknameRef = FIRDatabaseReference()
    var nicknameRefHandle = FIRDatabaseHandle()
    var convos = [Convo]()
    var convo = Convo()
    var nickname = ""
    var shouldShowConvo = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
        observeUnread()
        observeConvos()
        observeNickname()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        self.tabBarController?.tabBar.hidden = false
        
        if shouldShowConvo {
            let convoViewController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.Identifiers.ConvoViewController) as! ConvoViewController
            convoViewController.convo = convo
            convoViewController.hidesBottomBarWhenPushed = true
            shouldShowConvo = false
            convo = Convo()
            self.navigationController!.pushViewController(convoViewController, animated: true)
        }
    }
    
    deinit {
        unreadRef.removeObserverWithHandle(unreadRefHandle)
        convosRef.removeObserverWithHandle(convosRefHandle)
        nicknameRef.removeObserverWithHandle(nicknameRefHandle)
    }

    func setUp() {
        tableView.delaysContentTouches = false
        for case let scrollView as UIScrollView in tableView.subviews {
            scrollView.delaysContentTouches = false
        }
        //        edgesForExtendedLayout = .All
        //        tableView.contentInset = UIEdgeInsetsMake(0, 0, CGRectGetHeight(self.tabBarController!.tabBar.frame), 0)
    }
    
    // MARK: - Database
    func observeUnread() {
        unreadRef = ref.child("unread").child(proxy.key)
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { snapshot in
            //            if let unread = snapshot.value as? Int {
            //                self.navigationItem.title = "\(self.proxy.key) \(unread.unreadTitleSuffix())"
            //            }
        })
    }
    
    func observeConvos() {
        convosRef = ref.child("convos").child(proxy.key)
        convosRefHandle = convosRef.queryOrderedByChild("timestamp").observeEventType(.Value, withBlock: { (snapshot) in
            var convos = [Convo]()
            for child in snapshot.children {
                var convo = Convo(anyObject: child.value)
                convo.unread = child.value["unread"] as? Int ?? 0
                convos.append(convo)
            }
            self.convos = convos.reverse()
            self.tableView.reloadData()
        })
    }
    
    func observeNickname() {
        nicknameRef = ref.child("proxies").child(proxy.owner).child(proxy.key).child("nickname")
        nicknameRefHandle = nicknameRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let nickname = snapshot.value as? String {
                self.nickname = nickname
            }
        })
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        view.endEditing(true)
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
        case 0:
            return 140
        default:
            return UITableViewAutomaticDimension
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
    
    // MARK: - Table view data source
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
            
        // Nickname
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("Proxy Info Header Cell", forIndexPath: indexPath) as! ProxyInfoHeaderCell
            cell.selectionStyle = .None
            cell.proxy = proxy
            cell.nicknameButton.addTarget(self, action: #selector(ProxyInfoTableViewController.editNickname), forControlEvents: .TouchUpInside)
            cell.editIconButton.addTarget(self, action: #selector(ProxyInfoTableViewController.editIcon), forControlEvents: .TouchUpInside)
            return cell
            
        // This proxy's convos
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Identifiers.ProxyCell, forIndexPath: indexPath) as! ProxyCell
            let convo = self.convos[indexPath.row]
            cell.titleLabel.attributedText = convoTitle(convo.convoNickname, proxyNickname: convo.proxyNickname, you: convo.senderProxy, them: convo.receiverProxy, size: 13, navBar: false)
            cell.timestampLabel.text = convo.timestamp.timeAgoFromTimeInterval()
            cell.messageLabel.text = convo.message
            cell.unreadLabel.text = convo.unread.unreadFormatted()
            return cell
        default: break
        }
        return UITableViewCell()
    }
    
    func confirmDelete() {
        let alert = UIAlertController(title: "Delete Proxy?", message: "You will not be able to see this proxy or its conversations again. Other users are not notified.", preferredStyle: .Alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .Destructive, handler: { (void) in
            self.api.deleteProxy(self.proxy, convos: self.convos)
            self.navigationController?.popViewControllerAnimated(true)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func editNickname() {
        let alert = UIAlertController(title: "Edit Nickname", message: "Only you see your nickname.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            textField.placeholder = "Enter A Nickname"
            textField.text = self.nickname
            textField.autocorrectionType = .Yes
            textField.autocapitalizationType = .Sentences
            textField.clearButtonMode = .WhileEditing
            textField.selectedTextRange = textField.textRangeFromPosition(textField.beginningOfDocument, toPosition: textField.endOfDocument)
        })
        alert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action) -> Void in
            let nickname = alert.textFields![0].text
            let trim = nickname!.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " "))
            if !(nickname != "" && trim == "") {
                self.api.updateProxyNickname(self.proxy, convos: self.convos, nickname: nickname!)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func editIcon() {
        
    }
    
    // MARK: - Select proxy view controller delegate
    func showNewConvo(convo: Convo) {
        self.convo = convo
        shouldShowConvo = true
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case Constants.Segues.ConvoSegue:
            if let dest = segue.destinationViewController as? ConvoViewController,
                let index = tableView.indexPathForSelectedRow?.row {
                dest.convo = convos[index]
                dest.hidesBottomBarWhenPushed = true
            }
        default:
            return
        }
    }
}