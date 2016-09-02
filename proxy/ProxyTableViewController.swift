//
//  ProxyTableViewController.swift
//  proxy
//
//  Created by Quan Vo on 9/1/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class ProxyTableViewController: UITableViewController, NewMessageViewControllerDelegate {
    
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
        observeUnread()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        observeConvos()
    }
    
    override func viewDidAppear(animated: Bool) {
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
    
    func observeUnread() {
        unreadRef = ref.child("convos").child(proxy.name).child("unread")
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { snapshot in
            if let unread = snapshot.value as? Int {
                self.navigationItem.title = "\(self.proxy.name) \(unread.unreadTitleSuffix())"
            }
        })
    }
    
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
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 5
        case 2: return convos.count
        default: return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch section {
        case 0: return "NICKNAME - only you see this"
        case 1: return ""
        case 2: return "CONVERSATIONS"
        default: break
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Identifiers.NicknameCell, forIndexPath: indexPath) as! NicknameCell
            switch indexPath.row {
            case 0:
                let nickname = proxy.nickname
                if nickname == "" {
                    cell.textLabel?.text = "Tap to edit"
                } else {
                    cell.textLabel?.text = nickname
                }
                cell.textLabel?.textColor = UIColor().blue()
                return cell
            default: break
            }
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Identifiers.NicknameCell, forIndexPath: indexPath) as! NicknameCell
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Messages Received"
                return cell
            case 1:
                cell.textLabel?.text = "Messages Sent"
                return cell
            case 2:
                cell.textLabel?.text = "Proxies Interacted With"
                return cell
            case 3:
                cell.textLabel?.text = "Date Created"
                return cell
            case 4:
                cell.textLabel?.text = "Delete Proxy"
                cell.textLabel?.textColor = UIColor.redColor()
                cell.textLabel!.font = UIFont.systemFontOfSize(17, weight: UIFontWeightUltraLight)
                return cell
            default: break
            }
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Identifiers.ProxyTableViewCell, forIndexPath: indexPath) as! ProxyTableViewCell
            let convo = self.convos[indexPath.row]
            cell.titleLabel.attributedText = convoTitle(convo.nickname, you: convo.senderProxy, them: convo.receiverProxy)
            cell.timestampLabel.text = convo.timestamp.timeAgoFromTimeInterval()
            cell.messageLabel.text = convo.message
            cell.unreadLabel.text = convo.unread.unreadFormatted()
            return cell
        default: break
        }
        return UITableViewCell()
    }
    
    // MARK: - Select proxy view controller delegate
    
    func showNewConvo(convo: Convo) {
        self.convo = convo
        shouldShowConvo = true
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case Constants.Segues.NewMessageSegue:
            if let destination = segue.destinationViewController as? NewMessageViewController {
                destination.delegate = self
                destination.proxy = proxy
            }
        case Constants.Segues.ConvoSegue:
            if let destination = segue.destinationViewController as? ConvoViewController,
                let index = tableView.indexPathForSelectedRow?.row {
                destination.convo = convos[index]
                destination.hidesBottomBarWhenPushed = true
            }
        default:
            return
        }
    }
}