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
    var delegate: ConvoInfoTableViewControllerDelegate!
    
    var receiverIconRef = FIRDatabaseReference()
    var receiverIconRefHandle = FIRDatabaseHandle()
    var receiverIcon: String?
    
    var receiverNickname: String?
    
    var senderProxyRef = FIRDatabaseReference()
    var senderProxyRefHandle = FIRDatabaseHandle()
    var senderProxy: Proxy?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        observeReceiverIcon()
        observeSenderProxy()
    }
    
    deinit {
        receiverIconRef.removeObserverWithHandle(receiverIconRefHandle)
        senderProxyRef.removeObserverWithHandle(senderProxyRefHandle)
    }
    
    // MARK: - Set up
    func setUp() {
        navigationItem.title = "Conversation"
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Identifiers.Cell)
        tableView.delaysContentTouches = false
        for case let scrollView as UIScrollView in tableView.subviews {
            scrollView.delaysContentTouches = false
        }
        receiverIconRef = ref.child(Path.Proxies).child(convo.receiverId).child(convo.receiverProxy)
        senderProxyRef = ref.child(Path.Proxies).child(convo.senderId).child(convo.senderProxy)
    }
    
    // MARK: - Database
    func observeReceiverIcon() {
        receiverIconRefHandle = receiverIconRef.observeEventType(.Value, withBlock: { (snapshot) in
            self.receiverIcon = snapshot.value as? String
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        })
    }
    
    func observeSenderProxy() {
        senderProxyRefHandle = senderProxyRef.observeEventType(.Value, withBlock: { (snapshot) in
            self.senderProxy = Proxy(anyObject: snapshot.value!)
            self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
        })
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
            showProxyInfoTableViewController()
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
            if let receiverIcon = self.receiverIcon {
                
                // Set icon
                cell.iconImageView.kf_indicatorType = .Activity
                self.api.getURL(forIcon: receiverIcon) { (url) in
                    guard let url = url.absoluteString where url != "" else { return }
                    cell.iconImageView.kf_setImageWithURL(NSURL(string: url), placeholderImage: nil)
                }
                
                // Set up
                cell.nicknameButton.addTarget(self, action: #selector(ConvoInfoTableViewController.showEditReceiverProxyNicknameAlert), forControlEvents: .TouchUpInside)
            }
            cell.selectionStyle = .None
            
            return cell
            
        // Sender proxy info
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.SenderProxyInfoCell, forIndexPath: indexPath) as! SenderProxyInfoCell
            if let senderProxy = senderProxy {
                
                // Set icon
                cell.iconImageView.kf_indicatorType = .Activity
                api.getURL(forIcon: senderProxy.icon) { (url) in
                    guard let url = url.absoluteString where url != "" else { return }
                    cell.iconImageView.kf_setImageWithURL(NSURL(string: url), placeholderImage: nil)
                }
                
                // Set labels
                cell.nameLabel.text = senderProxy.key
                cell.nicknameButton.setTitle(senderProxy.nickname == "" ? "Enter A Nickname" : senderProxy.nickname, forState: .Normal)
                
                // Set up
                cell.accessoryType = .DisclosureIndicator
                cell.nicknameButton.addTarget(self, action: #selector(ConvoInfoTableViewController.showEditSenderProxyNicknameAlert), forControlEvents: .TouchUpInside)
                cell.changeIconButton.addTarget(self, action: #selector(ConvoInfoTableViewController.showIconPickerCollectionViewController), forControlEvents: .TouchUpInside)
            }
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.Cell, forIndexPath: indexPath)
            cell.selectionStyle = .None
            switch indexPath.row {
                
            // Allow pictures & video
            case 0:
                cell.textLabel?.text = "Allow pictures & video"
                
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
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.Cell, forIndexPath: indexPath)
            switch indexPath.row {
                
            // Leave convo
            case 0:
                cell.textLabel?.text = "Leave conversation"
                cell.textLabel?.textColor = UIColor.redColor()
                cell.textLabel!.font = UIFont.systemFontOfSize(17, weight: UIFontWeightRegular)
                return cell
                
            // Block user
            case 1:
                cell.textLabel?.text = "Block user"
                cell.textLabel?.textColor = UIColor.redColor()
                cell.textLabel!.font = UIFont.systemFontOfSize(17, weight: UIFontWeightRegular)
                return cell
                
            default: break
            }
            
        default: break
        }
        return UITableViewCell()
    }
    
    func showEditReceiverProxyNicknameAlert() {
        let alert = UIAlertController(title: "Edit Receiver's Nickname", message: "Only you see this nickname.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            textField.autocapitalizationType = .Sentences
            textField.autocorrectionType = .Yes
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
                self.api.set(nickname: nickname!, forReceiverInConvo: self.convo)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showEditSenderProxyNicknameAlert() {
        let alert = UIAlertController(title: "Edit Nickname", message: "Only you see your nickname.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            textField.autocapitalizationType = .Sentences
            textField.autocorrectionType = .Yes
            textField.clearButtonMode = .WhileEditing
            textField.placeholder = "Enter A Nickname"
            if let senderNickname = self.senderProxy?.nickname {
                textField.text = senderNickname
            } else {
                textField.text = ""
            }
        })
        alert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action) -> Void in
            let nickname = alert.textFields![0].text
            let trim = nickname!.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " "))
            if !(nickname != "" && trim == "") {
                self.api.set(nickname: nickname!, forProxy: self.senderProxy!)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showLeaveConvoAlert() {
        let alert = UIAlertController(title: "Leave Conversation?", message: "The other user will not be notified.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Leave", style: .Destructive, handler: { (void) in
            self.api.leave(convo: self.convo)
            self.delegate?.leftConvo()
            self.navigationController?.popViewControllerAnimated(true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    func showIconPickerCollectionViewController() {
        api.getConvos(forProxy: senderProxy!) { (convos) in
            let dest = self.storyboard?.instantiateViewControllerWithIdentifier(Identifiers.IconPickerCollectionViewController) as! IconPickerCollectionViewController
            dest.proxy = self.senderProxy!
            dest.convos = convos
            self.navigationController?.pushViewController(dest, animated: true)
        }
    }
    
    func showProxyInfoTableViewController() {
        if let senderProxy = senderProxy {
            let dest = self.storyboard!.instantiateViewControllerWithIdentifier(Identifiers.ProxyInfoTableViewController) as! ProxyInfoTableViewController
            dest.proxy = senderProxy
            self.navigationController!.pushViewController(dest, animated: true)
        }
    }
}
