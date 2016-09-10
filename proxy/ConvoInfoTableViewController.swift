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
    var nicknameRef = FIRDatabaseReference()
    var nicknameRefHandle = FIRDatabaseHandle()
    var proxyRef = FIRDatabaseReference()
    var proxyRefHandle = FIRDatabaseHandle()
    var convo = Convo()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Identifiers.BasicCell)
        
//        observeNickname()
//        observeProxy()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        // The convo VC needs to hide the tab bar in order for its text input
        // bar to work, so we unhide it again here.
        self.tabBarController?.tabBar.hidden = false
    }
    
    deinit {
        // Stop observing this node on deinit
        nicknameRef.removeObserverWithHandle(nicknameRefHandle)
        proxyRef.removeObserverWithHandle(proxyRefHandle)
    }
    
    func setUpUI() {
        navigationItem.title = "Conversation"
        self.edgesForExtendedLayout = .All
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, CGRectGetHeight(self.tabBarController!.tabBar.frame), 0)
    }
    
    // Watch the database for nickname changes to this convo. When they happen,
    // update the title of the view to reflect them.
    func observeNickname() {
        nicknameRef = ref.child("convos").child(api.uid).child(convo.key).child("receiverNickname")
        nicknameRefHandle = nicknameRef.observeEventType(.Value, withBlock: { snapshot in
            if let nickname = snapshot.value as? String {
                self.convo.receiverNickname = nickname
            }
        })
    }
    
    // Observe the user's proxy to keep note of changes and update the title
    // and 'you' cell
    func observeProxy() {
        proxyRef = ref.child("proxies").child(api.uid).child(convo.senderProxy).child("nickname")
        proxyRefHandle = proxyRef.observeEventType(.Value, withBlock: { snapshot in
            if let nickname = snapshot.value as? String {
                self.convo.senderNickname = nickname
                let indexPath = NSIndexPath(forRow: 0, inSection: 2)
                if self.tableView.dequeueReusableCellWithIdentifier(Identifiers.BasicCell, forIndexPath: indexPath) != nil {
                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
            }
        })
    }
    
    // To dismiss keyboard when user drags down on the view
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    //Mark: - Table view delegate
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 5
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return 1
        case 3: return 3
        case 4: return 2
        default: return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "NICKNAME - only you see this"
        default: return nil
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 1: return "them"
        case 2: return "you"
        case 4: return "Users are not notified when you take these actions."
        default: return nil
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        switch indexPath.section {
        case 2:
            goToProxy()
        case 4:
            switch indexPath.row {
            case 0:
                confirmLeaveConvo()
            default:
                return
            }
        default: return
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch indexPath.section {
            
        // The nickname editor cell
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.ConvoNicknameCell, forIndexPath: indexPath) as! ConvoNicknameCell
            
            cell.convo = convo
            
            // Needed in order for text field inside a cell to work
            cell.selectionStyle = .None
            
            return cell
            
            // The 'Members' section
        // 'them'
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.BasicCell, forIndexPath: indexPath)
            cell.textLabel?.text = convo.receiverProxy
            return cell
            
        // 'you'
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.BasicCell, forIndexPath: indexPath)
            cell.textLabel?.attributedText = youTitle(convo.senderProxy, nickname: convo.senderNickname)
            cell.accessoryType = .DisclosureIndicator
            return cell
            
        // The 'Settings' section
        case 3:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.BasicCell, forIndexPath: indexPath)
            cell.selectionStyle = .None
            
            switch indexPath.row {
                
            // Allow pictures, videos, etc.
            case 0:
                cell.textLabel?.text = "Allow pictures, videos, etc."
                
                // add switch control
                let settingSwitch = UISwitch()
                settingSwitch.tag = indexPath.row
                //                settingSwitch.on = defaults.boolForKey(row.rawValue) ?? false
                //                settingSwitch.addTarget(self, action: #selector(switchValueChanged), forControlEvents: .ValueChanged)
                cell.accessoryView = settingSwitch
                return cell
                
            // Do not disturb
            case 1:
                cell.textLabel?.text = "Do not disturb"
                
                // add switch control
                let settingSwitch = UISwitch()
                settingSwitch.tag = indexPath.row
                //                settingSwitch.on = defaults.boolForKey(row.rawValue) ?? false
                //                settingSwitch.addTarget(self, action: #selector(switchValueChanged), forControlEvents: .ValueChanged)
                cell.accessoryView = settingSwitch
                return cell
                
            // Send read receipts
            case 2:
                cell.textLabel?.text = "Send read receipts"
                
                // add switch control
                let settingSwitch = UISwitch()
                settingSwitch.tag = indexPath.row
                //                settingSwitch.on = defaults.boolForKey(row.rawValue) ?? false
                //                settingSwitch.addTarget(self, action: #selector(switchValueChanged), forControlEvents: .ValueChanged)
                cell.accessoryView = settingSwitch
                return cell
                
            default: break
            }
            
        // Block user/Leave conversation
        case 4:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.BasicCell, forIndexPath: indexPath)
            switch indexPath.row {
                
            // Block user
            case 0:
                cell.textLabel?.text = "Leave conversation"
                cell.textLabel?.textColor = UIColor.redColor()
                cell.textLabel!.font = UIFont.systemFontOfSize(17, weight: UIFontWeightUltraLight)
                return cell
                
            // Leave conversation
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
    
    // Request the proxy from the API. On successful callback, use it to push
    // the proxy VC
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
    
    // Leave the conversation. Call API to do the work and then pop the VC.
    func confirmLeaveConvo() {
        let alert = UIAlertController(title: "Leave Conversation?", message: "The other user will not be notified.", preferredStyle: .Alert)
        let deleteAction = UIAlertAction(title: "Leave", style: .Destructive, handler: { (void) in
            self.api.leaveConvo(self.convo.senderProxy, convo: self.convo)
            self.navigationController?.popViewControllerAnimated(true)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
}