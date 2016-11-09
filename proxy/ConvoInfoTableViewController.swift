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
    
    var receiverNicknameRef = FIRDatabaseReference()
    var receiverNicknameRefHandle = FIRDatabaseHandle()
    var receiverNickname: String?
    
    var senderNicknameRef = FIRDatabaseReference()
    var senderNicknameRefHandle = FIRDatabaseHandle()
    var senderNickname: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        observeReceiverNickname()
        observerSenderNickname()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        checkStatus()
    }
    
    deinit {
        receiverNicknameRef.removeObserverWithHandle(receiverNicknameRefHandle)
        senderNicknameRef.removeObserverWithHandle(senderNicknameRefHandle)
    }
    
    // MARK: - Set up
    func setUp() {
        navigationItem.title = "Conversation"
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Identifiers.Cell)
        tableView.delaysContentTouches = false
        for case let scrollView as UIScrollView in tableView.subviews {
            scrollView.delaysContentTouches = false
        }
        api.getProxy(withKey: convo.senderProxy, belongingToUser: convo.senderId) { (proxy) in
            self.senderProxy = proxy
            self.tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
        }
        receiverNicknameRef = ref.child(Path.Convos).child(convo.senderId).child(convo.key).child(Path.ReceiverNickname)
        senderNicknameRef = ref.child(Path.Convos).child(convo.senderId).child(convo.key).child(Path.SenderNickname)
    }
    
    // MARK: - Database
    func checkStatus() {
        checkLeftConvo()
        checkDeletedProxy()
        checkIsBlocking()
    }
    
    func checkLeftConvo() {
        ref.child(Path.Convos).child(convo.senderId).child(convo.key).child(Path.SenderLeftConvo).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let leftConvo = snapshot.value as? Bool where leftConvo {
                self.navigationController?.popViewControllerAnimated(true)
            }
        })
    }
    
    func checkDeletedProxy() {
        ref.child(Path.Convos).child(convo.senderId).child(convo.key).child(Path.SenderDeletedProxy).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let deletedProxy = snapshot.value as? Bool where deletedProxy {
                self.navigationController?.popViewControllerAnimated(true)
            }
        })
    }
    
    func checkIsBlocking() {
        ref.child(Path.Convos).child(convo.senderId).child(convo.key).child(Path.SenderIsBlocking).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let isBlocking = snapshot.value as? Bool where isBlocking {
                self.navigationController?.popViewControllerAnimated(true)
            }
        })
    }
    
    func observeReceiverNickname() {
        receiverNicknameRefHandle = receiverNicknameRef.observeEventType(.Value, withBlock: { (snapshot) in
            guard let receiverNickname = snapshot.value as? String else { return }
            self.receiverNickname = receiverNickname
        })
    }
    
    func observerSenderNickname() {
        senderNicknameRefHandle = senderNicknameRef.observeEventType(.Value, withBlock: { (snapshot) in
            guard let senderNickname = snapshot.value as? String else { return }
            self.senderNickname = senderNickname
        })
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
        case 2: return "Users are not notified when you take these actions."
        default: return nil
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        switch indexPath.section {
        case 1: showProxyInfoTableViewController()
        case 2:
            switch indexPath.row {
            case 0: showLeaveConvoAlert()
            case 1: showBlockUserConfirmation()
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
            cell.selectionStyle = .None
            cell.nicknameButton.addTarget(self, action: #selector(ConvoInfoTableViewController.showEditReceiverProxyNicknameAlert), forControlEvents: .TouchUpInside)
            return cell
            
        // Sender proxy info
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.SenderProxyInfoCell, forIndexPath: indexPath) as! SenderProxyInfoCell
            if let senderProxy = senderProxy {
                cell.proxy = senderProxy
                cell.accessoryType = .DisclosureIndicator
                cell.nicknameButton.addTarget(self, action: #selector(ConvoInfoTableViewController.showEditSenderProxyNicknameAlert), forControlEvents: .TouchUpInside)
                cell.changeIconButton.addTarget(self, action: #selector(ConvoInfoTableViewController.showIconPickerCollectionViewController), forControlEvents: .TouchUpInside)
            }
            return cell
            
        case 2:
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
            if let senderNickname = self.senderNickname {
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
            self.navigationController?.popViewControllerAnimated(true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showBlockUserConfirmation() {
        let alert = UIAlertController(title: "Block User?", message: "You will no longer see any conversations with this user. You can unblock users in the 'Me' tab.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Block", style: .Destructive, handler: { (void) in
            self.api.blockReceiverInConvo(self.convo)
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
