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
    var senderProxy: Proxy?
    var delegate: ConvoInfoTableViewControllerDelegate?
    
    var receiverNicknameRef = FIRDatabaseReference()
    var receiverNicknameRefHandle = FIRDatabaseHandle()
    var receiverNickname: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        observeReceiverNickname()
    }
    
    deinit {
        receiverNicknameRef.removeObserverWithHandle(receiverNicknameRefHandle)
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
        api.getProxy(withKey: convo.senderProxy, ofUser: convo.senderId, completion: { (proxy) in
            self.senderProxy = proxy
            self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
        })
    }
    
    func observeReceiverNickname() {
        receiverNicknameRef = ref.child("convos").child(convo.senderId).child(convo.key).child("receiverNickname")
        receiverNicknameRefHandle = receiverNicknameRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let nickname = snapshot.value as? String {
                self.receiverNickname = nickname
            }
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
            label.text = "Them"
            view.addSubview(label)
            return view
            
        case 1:
            let view = UIView()
            let label = UILabel(frame: CGRectMake(0, 0, tableView.frame.width - 15, 30))
            label.autoresizingMask = .FlexibleRightMargin
            label.textAlignment = .Right
            label.font = label.font.fontWithSize(13)
            label.textColor = UIColor.grayColor()
            label.text = "You"
            view.addSubview(label)
            return view
            
        default: return nil
        }
    }
    
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
            showProxyInfoViewController()
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
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.ReceiverProxyInfoCell, forIndexPath: indexPath) as! ReceiverProxyInfoCell
            cell.convo = convo
            cell.nicknameButton.addTarget(self, action: #selector(ConvoInfoTableViewController.showEditReceiverProxyNicknameAlert), forControlEvents: .TouchUpInside)
            cell.accessoryType = .DisclosureIndicator
            return cell
            
        // Sender proxy info
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.SenderProxyInfoCell, forIndexPath: indexPath) as! SenderProxyInfoCell
            if let senderProxy = senderProxy {
                cell.proxy = senderProxy
                cell.nicknameButton.addTarget(self, action: #selector(ConvoInfoTableViewController.showEditNicknameAlert), forControlEvents: .TouchUpInside)
                cell.changeIconButton.addTarget(self, action: #selector(ConvoInfoTableViewController.showIconPickerViewController), forControlEvents: .TouchUpInside)
            }
            cell.accessoryType = .DisclosureIndicator
            cell.selectionStyle = .Default
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
    
    // Show alert for user to edit the receiver proxy's nickname for this convo.
    func showEditReceiverProxyNicknameAlert() {
        let alert = UIAlertController(title: "Edit Receiver's Nickname", message: "Only you see this nickname.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            textField.autocorrectionType = .Yes
            textField.autocapitalizationType = .Sentences
            textField.clearButtonMode = .WhileEditing
            textField.placeholder = "Enter A Nickname"
            if let receiverNickname = self.receiverNickname {
                textField.text = receiverNickname
            } else {
                textField.text = ""
            }
        })
        alert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action) -> Void in
            let nickname = alert.textFields![0].text
            let trim = nickname!.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " "))
            if !(nickname != "" && trim == "") {
                self.api.update(nickname: nickname!, forReceiverInConvo: self.convo)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // Show alert for user to edit their proxy's nickname.
    func showEditNicknameAlert() {
        let alert = UIAlertController(title: "Edit Nickname", message: "Only you see your nickname.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            textField.autocorrectionType = .Yes
            textField.autocapitalizationType = .Sentences
            textField.clearButtonMode = .WhileEditing
            textField.placeholder = "Enter A Nickname"
            textField.text = self.senderProxy?.nickname
        })
        alert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action) -> Void in
            let nickname = alert.textFields![0].text
            let trim = nickname!.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " "))
            if !(nickname != "" && trim == "") {
                self.api.update(nickname: nickname!, forProxy: self.senderProxy!)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    // Show VC to choose a new icon for the user's proxy.
    func showIconPickerViewController() {
        api.getConvos(forProxy: senderProxy!) { (convos) in
            let dest = self.storyboard?.instantiateViewControllerWithIdentifier(Identifiers.IconPickerCollectionViewController) as! IconPickerCollectionViewController
            dest.proxy = self.senderProxy!
            dest.convos = convos
            self.navigationController?.pushViewController(dest, animated: true)
        }
    }
    
    // Show the proxy info view controller.
    func showProxyInfoViewController() {
        if let senderProxy = senderProxy {
            let dest = self.storyboard!.instantiateViewControllerWithIdentifier(Identifiers.ProxyInfoTableViewController) as! ProxyInfoTableViewController
            dest.proxy = senderProxy
            self.navigationController!.pushViewController(dest, animated: true)
        }
    }
    
    // Show alert for user to confirm they want to leave this convo.
    // Leave the convo and pop VC if they say yes.
    func showLeaveConvoAlert() {
        let alert = UIAlertController(title: "Leave Conversation?", message: "The other user will not be notified.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Leave", style: .Destructive, handler: { (void) in
            self.api.leave(convo: self.convo)
            self.delegate?.didLeaveConvo()
            self.navigationController?.popViewControllerAnimated(true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
