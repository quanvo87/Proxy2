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
        
        self.navigationItem.title = self.proxy.name
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Constants.Identifiers.BasicCell)
        
        // For dynamic cell heights
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        
        observeUnread()
        observeConvos()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        // The convo VC needs to hide the tab bar in order for its text input
        // bar to work, so we unhide it again here.
        self.tabBarController?.tabBar.hidden = false
        
        // Goes to the convo if returning to this view from just sending a
        // message.
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
    
    // Observe the unread count for this proxy and keep the title updated
    func observeUnread() {
        unreadRef = ref.child("convos").child(proxy.name).child("unread")
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { snapshot in
            if let unread = snapshot.value as? Int {
                self.navigationItem.title = "\(self.proxy.name) \(unread.unreadTitleSuffix())"
            }
        })
    }
    
    // Observe the convos for this proxy
    // Users can tap these cells to go directly to the convo
    func observeConvos() {
        convosRef = ref.child("convos").child(proxy.name)
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
    
    // To dismiss keyboard when user drags down on the view
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
            
        // The nickname editor cell
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Identifiers.ProxyNicknameCell, forIndexPath: indexPath) as! ProxyNicknameCell
            switch indexPath.row {
            case 0:
                cell.proxyAndConvo = (proxy, convos)
                
                // Needed in order for text field inside a cell to work
                cell.selectionStyle = .None
                return cell
                
            default: break
            }
            
        // The delete cell
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
            
        // The table view of convos that the user can tap to enter into
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
    
    // If user confirms, make a call to the API to do the work to delete the 
    // proxy and then go back to the proxy browsing screen. This proxy will be
    // gone and inaccessible afterwards.
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
    
    // Communication from the new message VC if the user sends a message from
    // this tab. Helps this VC know that it should transition to the convo.
    func showNewConvo(convo: Convo) {
        self.convo = convo
        shouldShowConvo = true
    }
    
    // MARK: - Navigation
    
    // Sets the appropriate data depending on if the user is sending a new
    // message or going into an exisiting one from this VC.
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