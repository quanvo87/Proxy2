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
    var convos = [Convo]()
    var convo = Convo()
    var shouldShowConvo = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = self.proxy.key
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Constants.Identifiers.BasicCell)
        
        observeUnread()
        observeConvos()
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
    }
    
    // MARK: - Database
    func observeUnread() {
        unreadRef = ref.child("unread").child(proxy.key)
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { snapshot in
            if let unread = snapshot.value as? Int {
                self.navigationItem.title = "\(self.proxy.key) \(unread.unreadTitleSuffix())"
            }
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
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    // MARK: - Table view delegate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return convos.count
        default: return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "NICKNAME - only you see this"
        case 2: return "CONVERSATIONS"
        default: return nil
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 1: return "Users are not notified when you delete your Proxy."
        case 2:
            if convos.count == 0 {
                return "No conversations yet. Start one with the 'New' button in the top right!"
            } else {
                return nil
            }
        default: return nil
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        switch indexPath.section {
        case 1:
            switch indexPath.row {
            case 0:
                confirmDelete()
            default: return
            }
        default: return
        }
    }
    
    // MARK: - Table view data source
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch indexPath.section {
            
        // Nickname
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Identifiers.ProxyNicknameCell, forIndexPath: indexPath) as! ProxyNicknameCell
            switch indexPath.row {
            case 0:
                cell.proxyAndConvo = (proxy, convos)
                cell.selectionStyle = .None
                return cell
            default: break
            }
            
        // Delete
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Identifiers.BasicCell, forIndexPath: indexPath)
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Delete"
                cell.textLabel?.textColor = UIColor.redColor()
                cell.textLabel!.font = UIFont.systemFontOfSize(17, weight: UIFontWeightUltraLight)
                return cell
            default: break
            }
            
        // This proxy's convos
        case 2:
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