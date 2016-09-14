//
//  ConvoInfoTableViewController.swift
//  proxy
//
//  Created by Quan Vo on 9/3/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class ConvoInfoTableViewController: UITableViewController {
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var convo = Convo()
    
    var receiverProxyRef = FIRDatabaseReference()
    var receiverProxyRefHandle = FIRDatabaseHandle()
    var receiverProxy: Proxy?
    
    var senderProxyRef = FIRDatabaseReference()
    var senderProxyRefHandle = FIRDatabaseHandle()
    var senderProxy: Proxy?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        observeReceiverProxy()
        observeSenderProxy()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.tabBarController?.tabBar.hidden = false
    }
    
    deinit {
        receiverProxyRef.removeObserverWithHandle(receiverProxyRefHandle)
        senderProxyRef.removeObserverWithHandle(senderProxyRefHandle)
    }
    
    func setUp() {
        navigationItem.title = "Conversation"
        edgesForExtendedLayout = .All
        tableView.contentInset = UIEdgeInsetsMake(0, 0, CGRectGetHeight(self.tabBarController!.tabBar.frame), 0)
        tableView.delaysContentTouches = false
        for case let scrollView as UIScrollView in tableView.subviews {
            scrollView.delaysContentTouches = false
        }
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Identifiers.BasicCell)
    }
    
    func observeReceiverProxy() {
        receiverProxyRef = ref.child("proxies").child(convo.receiverId).child(convo.receiverProxy)
        receiverProxyRefHandle = receiverProxyRef.observeEventType(.Value, withBlock: { snapshot in
            let proxy = Proxy(anyObject: snapshot.value!)
            self.receiverProxy = proxy
            let indexPath = NSIndexPath(forRow: 0, inSection: 0)
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        })
    }
    
    func observeSenderProxy() {
        senderProxyRef = ref.child("proxies").child(convo.senderId).child(convo.senderProxy)
        senderProxyRefHandle = senderProxyRef.observeEventType(.Value, withBlock: { snapshot in
            let proxy = Proxy(anyObject: snapshot.value!)
            self.senderProxy = proxy
            let indexPath = NSIndexPath(forRow: 0, inSection: 1)
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        })
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    //Mark: - Table view delegate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return 3
        case 3: return 2
        default: return 0
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0: return CGFloat.min
        default: return UITableViewAutomaticDimension
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return 80
        case 1: return 80
        default: return UITableViewAutomaticDimension
        }
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 0: return 15
        case 1: return 15
        default: return UITableViewAutomaticDimension
        }
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch section {
        
        case 0:
            let view = UIView()
            let label = UILabel(frame: CGRectMake(15, 0, tableView.frame.width, 30))
            label.font = label.font.fontWithSize(13)
            label.textColor = UIColor.grayColor()
//            label.baselineAdjustment = .AlignCenters
            label.text = "Them"
            view.addSubview(label)
            return view
            
        case 1:
            let view = UIView()
            let label = UILabel(frame: CGRectMake(0, 0, tableView.frame.width - 15, 30))
            label.autoresizingMask = .FlexibleRightMargin
            label.font = label.font.fontWithSize(13)
            label.textColor = UIColor.grayColor()
//            label.baselineAdjustment = .AlignCenters
            label.textAlignment = .Right
            label.text = "You"
            view.addSubview(label)
            return view
            
        default: return nil
        }
    }
    
//    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
//        switch section {
//        case 0: return 25
//        default: return UITableViewAutomaticDimension
//        }
//    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0: return "Them"
        case 3: return "Users are not notified when you take these actions."
        default: return nil
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        switch indexPath.section {
        case 1:
            goToProxy()
        case 3:
            switch indexPath.row {
            case 0:
                showLeaveConvoAlert()
            default:
                return
            }
        default: return
        }
    }
    
    // MARK: - Table view data source
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
            
        // Receiver proxy info
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.ThemProxyInfoHeaderCell, forIndexPath: indexPath) as! ProxyInfoHeaderCell
            if let receiverProxy = receiverProxy {
                cell.proxy = receiverProxy
            }
            cell.accessoryType = .DisclosureIndicator
            return cell
            
        // Sender proxy info
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.ProxyInfoHeaderCell, forIndexPath: indexPath) as! ProxyInfoHeaderCell
            if let senderProxy = senderProxy {
                cell.proxy = senderProxy
            }
            cell.accessoryType = .DisclosureIndicator
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.BasicCell, forIndexPath: indexPath)
            cell.selectionStyle = .None
            switch indexPath.row {
                
            // Allow pictures, videos, etc.
            case 0:
                cell.textLabel?.text = "Allow pictures, videos, etc."
                
                let settingSwitch = UISwitch()
                settingSwitch.tag = indexPath.row
                //                settingSwitch.on = defaults.boolForKey(row.rawValue) ?? false
                //                settingSwitch.addTarget(self, action: #selector(switchValueChanged), forControlEvents: .ValueChanged)
                cell.accessoryView = settingSwitch
                return cell
                
            // Do not disturb
            case 1:
                cell.textLabel?.text = "Do not disturb"
                
                let settingSwitch = UISwitch()
                settingSwitch.tag = indexPath.row
                //                settingSwitch.on = defaults.boolForKey(row.rawValue) ?? false
                //                settingSwitch.addTarget(self, action: #selector(switchValueChanged), forControlEvents: .ValueChanged)
                cell.accessoryView = settingSwitch
                return cell
                
            // Send read receipts
            case 2:
                cell.textLabel?.text = "Send read receipts"
                
                let settingSwitch = UISwitch()
                settingSwitch.tag = indexPath.row
                //                settingSwitch.on = defaults.boolForKey(row.rawValue) ?? false
                //                settingSwitch.addTarget(self, action: #selector(switchValueChanged), forControlEvents: .ValueChanged)
                cell.accessoryView = settingSwitch
                return cell
                
            default: break
            }
            
        case 3:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.BasicCell, forIndexPath: indexPath)
            switch indexPath.row {
                
            // Leave convo
            case 0:
                cell.textLabel?.text = "Leave conversation"
                cell.textLabel?.textColor = UIColor.redColor()
                cell.textLabel!.font = UIFont.systemFontOfSize(17, weight: UIFontWeightUltraLight)
                return cell
                
            // Block user
            case 1:
                cell.textLabel?.text = "Block user"
                cell.textLabel?.textColor = UIColor.redColor()
                cell.textLabel!.font = UIFont.systemFontOfSize(17, weight: UIFontWeightUltraLight)
                return cell
                
            default: break
            }
            
        default: break
        }
        return UITableViewCell()
    }
    
    // MARK: - Navigation
    // TODO: Change to goToSenderProxy or something, won't have to get proxy b/c we'll do that earlier
    func goToProxy() {
        // Lock the UI
        api.getProxy(withKey: convo.senderProxy) { (proxy) in
            // Unlock the UI
            if let proxy = proxy {
                // transition to proxy
                let dest = self.storyboard!.instantiateViewControllerWithIdentifier(Identifiers.ProxyInfoTableViewController) as! ProxyInfoTableViewController
                dest.proxy = proxy
                self.navigationController!.pushViewController(dest, animated: true)
            }
        }
    }
    
    // Show alert for user to confirm they want to leave this convo.
    // Leave the convo and pop VC if they say yes.
    func showLeaveConvoAlert() {
        let alert = UIAlertController(title: "Leave Conversation?", message: "The other user will not be notified.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Leave", style: .Destructive, handler: { (void) in
            self.api.leave(convo: self.convo)
            self.navigationController?.popViewControllerAnimated(true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}