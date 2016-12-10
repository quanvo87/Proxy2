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
    var convo = Convo()
    var senderProxy: Proxy?
    
    var receiverIconRef = FIRDatabaseReference()
    var receiverIconRefHandle = FIRDatabaseHandle()
    var receiverIconURL = NSURL()
    
    var receiverNicknameRef = FIRDatabaseReference()
    var receiverNicknameRefHandle = FIRDatabaseHandle()
    var receiverNickname: String?
    
    var senderIconRef = FIRDatabaseReference()
    var senderIconRefHandle = FIRDatabaseHandle()
    var senderIconURL = NSURL()
    
    var senderNicknameRef = FIRDatabaseReference()
    var senderNicknameRefHandle = FIRDatabaseHandle()
    var senderNickname: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Conversation"
        
        for case let scrollView as UIScrollView in tableView.subviews {
            scrollView.delaysContentTouches = false
        }
        tableView.delaysContentTouches = false
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Identifiers.Cell)
        
        api.getProxy(withKey: convo.senderProxy, belongingToUser: convo.senderId) { (proxy) in
            self.senderProxy = proxy
        }
        
        receiverIconRef = api.ref.child(Path.Convos).child(convo.senderId).child(convo.key).child(Path.Icon)
        receiverNicknameRef = api.ref.child(Path.Convos).child(convo.senderId).child(convo.key).child(Path.ReceiverNickname)
        senderIconRef = api.ref.child(Path.Proxies).child(convo.senderId).child(convo.senderProxy).child(Path.Icon)
        senderNicknameRef = api.ref.child(Path.Convos).child(convo.senderId).child(convo.key).child(Path.SenderNickname)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        // Check if convo info should be closed
        api.ref.child(Path.Convos).child(convo.senderId).child(convo.key).child(Path.SenderLeftConvo).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let leftConvo = snapshot.value as? Bool where leftConvo {
                self.close()
            }
        })
        
        api.ref.child(Path.Convos).child(convo.senderId).child(convo.key).child(Path.SenderDeletedProxy).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let deletedProxy = snapshot.value as? Bool where deletedProxy {
                self.close()
            }
        })
        
        api.ref.child(Path.Convos).child(convo.senderId).child(convo.key).child(Path.SenderIsBlocking).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let isBlocking = snapshot.value as? Bool where isBlocking {
                self.close()
            }
        })
        
        // Observe database values
        receiverIconRefHandle = receiverIconRef.observeEventType(.Value, withBlock: { (snapshot) in
            guard let icon = snapshot.value as? String where icon != "" else { return }
            self.api.getURL(forIcon: icon) { (url) in
                guard let url = url else { return }
                self.receiverIconURL = url
                self.tableView.reloadData()
            }
        })
        
        receiverNicknameRefHandle = receiverNicknameRef.observeEventType(.Value, withBlock: { (snapshot) in
            guard let receiverNickname = snapshot.value as? String else { return }
            self.receiverNickname = receiverNickname
            self.tableView.reloadData()
        })
        
        senderIconRefHandle = senderIconRef.observeEventType(.Value, withBlock: { (snapshot) in
            guard let icon = snapshot.value as? String where icon != "" else { return }
            self.api.getURL(forIcon: icon) { (url) in
                guard let url = url else { return }
                self.senderIconURL = url
                self.tableView.reloadData()
            }
        })
        
        senderNicknameRefHandle = senderNicknameRef.observeEventType(.Value, withBlock: { (snapshot) in
            guard let senderNickname = snapshot.value as? String else { return }
            self.senderNickname = senderNickname
            self.tableView.reloadData()
        })
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        receiverIconRef.removeObserverWithHandle(receiverNicknameRefHandle)
        receiverNicknameRef.removeObserverWithHandle(receiverNicknameRefHandle)
        senderIconRef.removeObserverWithHandle(senderIconRefHandle)
        senderNicknameRef.removeObserverWithHandle(senderNicknameRefHandle)
    }
    
    func close() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    //Mark: - Table view delegate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return 2
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
            label.text = "Them"
            label.textColor = UIColor.grayColor()
            view.addSubview(label)
            return view
            
        case 1:
            let view = UIView()
            let label = UILabel(frame: CGRectMake(0, 0, tableView.frame.width - 15, 30))
            label.autoresizingMask = .FlexibleRightMargin
            label.font = label.font.fontWithSize(13)
            label.text = "You"
            label.textAlignment = .Right
            label.textColor = UIColor.grayColor()
            view.addSubview(label)
            return view
            
        default: return nil
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0: return "Them"
        case 2: return "Users are not notified when you take these actions."
        default: return nil
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
            
        // Receiver proxy info
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.ReceiverProxyInfoCell, forIndexPath: indexPath) as! ReceiverProxyInfoCell
            
            cell.iconImageView.kf_indicatorType = .Activity
            cell.iconImageView = nil
            cell.iconImageView.kf_setImageWithURL(receiverIconURL, placeholderImage: nil)
            cell.nameLabel.text = convo.receiverProxy
            
            if receiverNickname == "" {
                cell.nicknameButton.setTitle("Enter A Nickname", forState: .Normal)
            } else {
                cell.nicknameButton.setTitle(receiverNickname, forState: .Normal)
            }
            
            cell.nicknameButton.addTarget(self, action: #selector(ConvoInfoTableViewController.editReceiverNickname), forControlEvents: .TouchUpInside)
            
            cell.selectionStyle = .None
            
            return cell
            
        // Sender proxy info
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.SenderProxyInfoCell, forIndexPath: indexPath) as! SenderProxyInfoCell
            
            cell.iconImageView.kf_indicatorType = .Activity
            cell.iconImageView = nil
            cell.iconImageView.kf_setImageWithURL(senderIconURL, placeholderImage: nil)
            cell.nameLabel.text = convo.senderProxy
            
            if senderNickname == "" {
                cell.nicknameButton.setTitle("Enter A Nickname", forState: .Normal)
            } else {
                cell.nicknameButton.setTitle(senderNickname, forState: .Normal)
            }
            
            cell.nicknameButton.addTarget(self, action: #selector(ConvoInfoTableViewController.editSenderNickname), forControlEvents: .TouchUpInside)
            cell.changeIconButton.addTarget(self, action: #selector(ConvoInfoTableViewController.goToIconPicker), forControlEvents: .TouchUpInside)
            
            cell.accessoryType = .DisclosureIndicator
            
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.Cell, forIndexPath: indexPath)
            switch indexPath.row {
                
            // Leave convo
            case 0:
                cell.textLabel!.font = UIFont.systemFontOfSize(17, weight: UIFontWeightRegular)
                cell.textLabel?.text = "Leave conversation"
                cell.textLabel?.textColor = UIColor.redColor()
                return cell
                
            // Block user
            case 1:
                cell.textLabel!.font = UIFont.systemFontOfSize(17, weight: UIFontWeightRegular)
                cell.textLabel?.text = "Block user"
                cell.textLabel?.textColor = UIColor.redColor()
                return cell
                
            default: break
            }
        default: break
        }
        return UITableViewCell()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        switch indexPath.section {
        case 1:
            
            // Go to sender proxy info
            if let senderProxy = senderProxy {
                let dest = self.storyboard!.instantiateViewControllerWithIdentifier(Identifiers.ProxyInfoTableViewController) as! ProxyInfoTableViewController
                dest.proxy = senderProxy
                self.navigationController!.pushViewController(dest, animated: true)
            }
            
        case 2:
            switch indexPath.row {
            case 0:
                
                // Leave convo
                let alert = UIAlertController(title: "Leave Conversation?", message: "The other user will not be notified.", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Leave", style: .Destructive, handler: { (void) in
                    self.api.leave(convo: self.convo)
                    self.navigationController?.popViewControllerAnimated(true)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                presentViewController(alert, animated: true, completion: nil)
                
            case 1:
                
                // Block user
                let alert = UIAlertController(title: "Block User?", message: "You will no longer see any conversations with this user. You can unblock users in the 'Me' tab.", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Block", style: .Destructive, handler: { (void) in
                    self.api.blockReceiverInConvo(self.convo)
                    self.navigationController?.popViewControllerAnimated(true)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                presentViewController(alert, animated: true, completion: nil)
                
            default:
                return
            }
        default: return
        }
    }
    
    func editReceiverNickname() {
        let alert = UIAlertController(title: "Edit Receiver's Nickname", message: "Only you see this nickname.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            if let receiverNickname = self.receiverNickname {
                textField.text = receiverNickname
            } else {
                textField.text = ""
            }
            textField.autocapitalizationType = .Sentences
            textField.autocorrectionType = .Yes
            textField.clearButtonMode = .WhileEditing
            textField.placeholder = "Enter A Nickname"
        })
        alert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action) -> Void in
            let nickname = alert.textFields![0].text
            let trim = nickname!.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " "))
            if !(nickname != "" && trim == "") {
                self.api.set(nickname: nickname!, forReceiverInConvo: self.convo)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func editSenderNickname() {
        let alert = UIAlertController(title: "Edit Nickname", message: "Only you see your nickname.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            if let senderNickname = self.senderNickname {
                textField.text = senderNickname
            } else {
                textField.text = ""
            }
            textField.autocapitalizationType = .Sentences
            textField.autocorrectionType = .Yes
            textField.clearButtonMode = .WhileEditing
            textField.placeholder = "Enter A Nickname"
        })
        alert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action) -> Void in
            let nickname = alert.textFields![0].text
            let trim = nickname!.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " "))
            if !(nickname != "" && trim == "") {
                self.api.set(nickname: nickname!, forProxy: self.senderProxy!)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func goToIconPicker() {
        api.getConvos(forProxy: senderProxy!) { (convos) in
            let dest = self.storyboard?.instantiateViewControllerWithIdentifier(Identifiers.IconPickerCollectionViewController) as! IconPickerCollectionViewController
            dest.proxy = self.senderProxy!
            dest.convos = convos
            self.navigationController?.pushViewController(dest, animated: true)
        }
    }
}
