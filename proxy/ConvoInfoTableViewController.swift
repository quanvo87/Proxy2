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
    
    var receiverIconRef = DatabaseReference()
    var receiverIconRefHandle = DatabaseHandle()
    var receiverIconURL = URL(fileURLWithPath: "")
    
    var receiverNicknameRef = DatabaseReference()
    var receiverNicknameRefHandle = DatabaseHandle()
    var receiverNickname: String?
    
    var senderIconRef = DatabaseReference()
    var senderIconRefHandle = DatabaseHandle()
    var senderIconURL = URL(fileURLWithPath: "")
    
    var senderNicknameRef = DatabaseReference()
    var senderNicknameRefHandle = DatabaseHandle()
    var senderNickname: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Conversation"
        
        for case let scrollView as UIScrollView in tableView.subviews {
            scrollView.delaysContentTouches = false
        }
        tableView.delaysContentTouches = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Identifiers.Cell)
        
        api.getProxy(withKey: convo.senderProxyKey, belongingToUserId: convo.senderId) { (proxy) in
            self.senderProxy = proxy
        }
        
        receiverIconRef = api.ref.child(Child.Proxies).child(convo.receiverId).child(convo.receiverProxyKey).child(Child.Icon)
        receiverNicknameRef = api.ref.child(Child.Convos).child(convo.senderId).child(convo.key).child(Child.ReceiverNickname)
        senderIconRef = api.ref.child(Child.Proxies).child(convo.senderId).child(convo.senderProxyKey).child(Child.Icon)
        senderNicknameRef = api.ref.child(Child.Convos).child(convo.senderId).child(convo.key).child(Child.SenderNickname)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        // Check if convo info should be closed
        api.ref.child(Child.Convos).child(convo.senderId).child(convo.key).child(Child.SenderLeftConvo).observeSingleEvent(of: .value, with: { (data) in
            if let leftConvo = data.value as? Bool, leftConvo {
                self.close()
            }
        })
        
        api.ref.child(Child.Convos).child(convo.senderId).child(convo.key).child(Child.SenderDeletedProxy).observeSingleEvent(of: .value, with: { (data) in
            if let deletedProxy = data.value as? Bool, deletedProxy {
                self.close()
            }
        })
        
        api.ref.child(Child.Convos).child(convo.senderId).child(convo.key).child(Child.ReceiverIsBlocked).observeSingleEvent(of: .value, with: { (data) in
            if let isBlocking = data.value as? Bool, isBlocking {
                self.close()
            }
        })
        
        // Observe database values
        receiverIconRefHandle = receiverIconRef.observe(.value, with: { (data) in
            guard let icon = data.value as? String, icon != "" else { return }
            self.api.getURL(forIconName: icon) { (url) in
                self.receiverIconURL = url
                self.tableView.reloadData()
            }
        })
        
        receiverNicknameRefHandle = receiverNicknameRef.observe(.value, with: { (data) in
            guard let receiverNickname = data.value as? String else { return }
            self.receiverNickname = receiverNickname
            self.tableView.reloadData()
        })
        
        senderIconRefHandle = senderIconRef.observe(.value, with: { (data) in
            guard let icon = data.value as? String, icon != "" else { return }
            self.api.getURL(forIconName: icon) { (url) in
                self.senderIconURL = url
                self.tableView.reloadData()
            }
        })
        
        senderNicknameRefHandle = senderNicknameRef.observe(.value, with: { (data) in
            guard let senderNickname = data.value as? String else { return }
            self.senderNickname = senderNickname
            self.tableView.reloadData()
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        receiverIconRef.removeObserver(withHandle: receiverNicknameRefHandle)
        receiverNicknameRef.removeObserver(withHandle: receiverNicknameRefHandle)
        senderIconRef.removeObserver(withHandle: senderIconRefHandle)
        senderNicknameRef.removeObserver(withHandle: senderNicknameRefHandle)
    }
    
    func close() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    //Mark: - Table view delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return 2
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return 80
        case 1: return 80
        default: return UITableViewAutomaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 0: return 15
        case 1: return 15
        default: return UITableViewAutomaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch section {
            
        case 0:
            let view = UIView()
            let label = UILabel(frame: CGRect(x: 15, y: 0, width: tableView.frame.width, height: 30))
            label.font = label.font.withSize(13)
            label.text = "Them"
            label.textColor = UIColor.gray
            view.addSubview(label)
            return view
            
        case 1:
            let view = UIView()
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.frame.width - 15, height: 30))
            label.autoresizingMask = .flexibleRightMargin
            label.font = label.font.withSize(13)
            label.text = "You"
            label.textAlignment = .right
            label.textColor = UIColor.gray
            view.addSubview(label)
            return view
            
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0: return "Them"
        case 2: return "Users are not notified when you take these actions."
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
            
        // Receiver proxy info
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.ReceiverProxyInfoCell, for: indexPath as IndexPath) as! ReceiverProxyInfoCell
            cell.nameLabel.text = convo.receiverProxyName
            cell.nicknameButton.setTitle(receiverNickname == "" ? "Enter A Nickname" : receiverNickname, for: .normal)
            cell.nicknameButton.addTarget(self, action: #selector(ConvoInfoTableViewController.editReceiverNickname), for: .touchUpInside)
            cell.iconImageView.image = nil
//            cell.iconImageView.kf.indicatorType = .activity
//            cell.iconImageView.kf.setImage(with: receiverIconURL, placeholder: nil, options: nil, progressBlock: nil, completionHandler: nil)
            cell.selectionStyle = .none
            return cell
            
        // Sender proxy info
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.SenderProxyInfoCell, for: indexPath as IndexPath) as! SenderProxyInfoCell
            cell.nameLabel.text = convo.senderProxyName
            cell.nicknameButton.setTitle(senderNickname == "" ? "Enter A Nickname" : senderNickname, for: .normal)
            cell.nicknameButton.addTarget(self, action: #selector(ConvoInfoTableViewController.editSenderNickname), for: .touchUpInside)
            cell.iconImageView.image = nil
//            cell.iconImageView.kf.indicatorType = .activity
//            cell.iconImageView.kf.setImage(with: senderIconURL, placeholder: nil, options: nil, progressBlock: nil, completionHandler: nil)
            cell.changeIconButton.addTarget(self, action: #selector(ConvoInfoTableViewController.goToIconPicker), for: .touchUpInside)
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.Cell, for: indexPath as IndexPath)
            switch indexPath.row {
                
            // Leave convo
            case 0:
                cell.textLabel!.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
                cell.textLabel?.text = "Leave conversation"
                cell.textLabel?.textColor = UIColor.red
                return cell
                
            // Block user
            case 1:
                cell.textLabel!.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
                cell.textLabel?.text = "Block user"
                cell.textLabel?.textColor = UIColor.red
                return cell
                
            default: break
            }
        default: break
        }
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        
        // Go to sender proxy info
        case 1:
            if let senderProxy = senderProxy {
                let dest = self.storyboard!.instantiateViewController(withIdentifier: Identifiers.ProxyInfoTableViewController) as! ProxyInfoTableViewController
                dest.proxy = senderProxy
                self.navigationController!.pushViewController(dest, animated: true)
            }
            
        case 2:
            switch indexPath.row {
            
            // Leave convo
            case 0:
                let alert = UIAlertController(title: "Leave Conversation?", message: "The other user will not be notified.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Leave", style: .destructive, handler: { (void) in
                    self.api.leaveConvo(self.convo)
                    _ = self.navigationController?.popViewController(animated: true)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
                
            // Block user
            case 1:
                let alert = UIAlertController(title: "Block User?", message: "You will no longer see any conversations with this user. You can unblock users in the 'Me' tab.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Block", style: .destructive, handler: { (void) in
                    self.api.blockReceiver(in: self.convo)
                    _ = self.navigationController?.popViewController(animated: true)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
                
            default:
                return
            }
        default: return
        }
    }
    
    @objc func editReceiverNickname() {
        let alert = UIAlertController(title: "Edit Receiver's Nickname", message: "Only you see this nickname.", preferredStyle: .alert)
        alert.addTextField(configurationHandler: { (textField) -> Void in
            if let receiverNickname = self.receiverNickname {
                textField.text = receiverNickname
            } else {
                textField.text = ""
            }
            textField.autocapitalizationType = .sentences
            textField.autocorrectionType = .yes
            textField.clearButtonMode = .whileEditing
            textField.placeholder = "Enter A Nickname"
        })
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (action) -> Void in
            let nickname = alert.textFields![0].text
            let trim = nickname!.trimmingCharacters(in: NSCharacterSet(charactersIn: " ") as CharacterSet)
            if !(nickname != "" && trim == "") {
                self.api.setNickname(nickname!, forReceiverInConvo: self.convo)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func editSenderNickname() {
        let alert = UIAlertController(title: "Edit Nickname", message: "Only you see your nickname.", preferredStyle: .alert)
        alert.addTextField(configurationHandler: { (textField) -> Void in
            if let senderNickname = self.senderNickname {
                textField.text = senderNickname
            } else {
                textField.text = ""
            }
            textField.autocapitalizationType = .sentences
            textField.autocorrectionType = .yes
            textField.clearButtonMode = .whileEditing
            textField.placeholder = "Enter A Nickname"
        })
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (action) -> Void in
            let nickname = alert.textFields![0].text
            let trim = nickname!.trimmingCharacters(in: NSCharacterSet(charactersIn: " ") as CharacterSet)
            if !(nickname != "" && trim == "") {
                self.api.setNickname(nickname!, for: self.senderProxy!)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func goToIconPicker() {
        api.getConvos(for: senderProxy!) { (convos) in
            let dest = self.storyboard?.instantiateViewController(withIdentifier: Identifiers.IconPickerCollectionViewController) as! IconPickerCollectionViewController
            dest.proxy = self.senderProxy!
            dest.convos = convos
            self.navigationController?.pushViewController(dest, animated: true)
        }
    }
}
