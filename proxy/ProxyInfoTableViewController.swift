//
//  ProxyInfoTableViewController.swift
//  proxy
//
//  Created by Quan Vo on 9/1/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class ProxyInfoTableViewController: UITableViewController, NewMessageViewControllerDelegate {
    
    let api = API.sharedInstance
    let ref = Database.database().reference()
    
    var proxyRef = DatabaseReference()
    var proxyRefHandle = DatabaseHandle()
    var proxy = Proxy()

    var convosRef = DatabaseReference()
    var convosRefHandle = DatabaseHandle()
    var convos = [Convo]()
    
    var convo: Convo?
    var shouldShowNewConvo = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let newMessageButton = UIButton(type: .custom)
        newMessageButton.addTarget(self, action: #selector(ProxyInfoTableViewController.showNewMessageViewController), for: UIControlEvents.touchUpInside)
        newMessageButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        newMessageButton.setImage(UIImage(named: "new-message.png"), for: UIControlState.normal)
        let newMessageBarButton = UIBarButtonItem(customView: newMessageButton)
        
        let deleteProxyButton = UIButton(type: .custom)
        deleteProxyButton.addTarget(self, action: #selector(ProxyInfoTableViewController.showDeleteProxyAlert), for: UIControlEvents.touchUpInside)
        deleteProxyButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        deleteProxyButton.setImage(UIImage(named: "delete.png"), for: UIControlState.normal)
        let deleteProxyBarButton = UIBarButtonItem(customView: deleteProxyButton)
        
        navigationItem.rightBarButtonItems = [newMessageBarButton, deleteProxyBarButton]
        
        for case let scrollView as UIScrollView in tableView.subviews {
            scrollView.delaysContentTouches = false
        }
        tableView.delaysContentTouches = false
        tableView.separatorStyle = .none
        
        proxyRef = ref.child(Path.Proxies).child(proxy.ownerId).child(proxy.key)
        convosRef = ref.child(Path.Convos).child(proxy.key)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        if convo != nil {
            ref.child(Path.Convos).child(convo!.senderId).child(convo!.key).child(Path.SenderLeftConvo).observeSingleEvent(of: .value, with: { (snapshot) in
                if let deleted = snapshot.value as? Bool, deleted {
                    _ = self.navigationController?.popViewController(animated: true)
                }
            })
        }
        
        if shouldShowNewConvo {
            let dest = self.storyboard!.instantiateViewController(withIdentifier: Identifiers.ConvoViewController) as! ConvoViewController
            dest.convo = convo!
            shouldShowNewConvo = false
            self.navigationController!.pushViewController(dest, animated: true)
        }
        
        proxyRefHandle = proxyRef.observe(.value, with: { (snapshot) in
            guard let proxy = Proxy(anyObject: snapshot.value! as AnyObject) else { return }
            self.proxy = proxy
            self.navigationItem.title = proxy.unread.asUnreadLabel()
            self.tableView.reloadData()
        })
        
        convosRefHandle = convosRef.queryOrdered(byChild: Path.Timestamp).observe(.value, with: { (snapshot) in
            self.convos = self.api.getConvos(from: snapshot)
            self.tableView.reloadData()
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        proxyRef.removeAllObservers()
        convosRef.removeAllObservers()
    }
    
    func showNewMessageViewController() {
        let dest = storyboard?.instantiateViewController(withIdentifier: Identifiers.NewMessageViewController) as! NewMessageViewController
        dest.newMessageViewControllerDelegate = self
        dest.sender = proxy
        navigationController?.pushViewController(dest, animated: true)
    }
    
    func showDeleteProxyAlert() {
        let alert = UIAlertController(title: "Delete Proxy?", message: "You will not be able to see this proxy or its conversations again. Other users will not be notified.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (void) in
            self.api.deleteProxy(self.proxy, with: self.convos)
            _ = self.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showIconPickerViewController() {
        let dest = self.storyboard?.instantiateViewController(withIdentifier: Identifiers.IconPickerCollectionViewController) as! IconPickerCollectionViewController
        dest.convos = convos
        dest.proxy = proxy
        self.navigationController?.pushViewController(dest, animated: true)
    }
    
    func showEditNicknameAlert() {
        let alert = UIAlertController(title: "Edit Nickname", message: "Only you see your nickname.", preferredStyle: .alert)
        alert.addTextField(configurationHandler: { (textField) -> Void in
            textField.autocapitalizationType = .sentences
            textField.autocorrectionType = .yes
            textField.clearButtonMode = .whileEditing
            textField.placeholder = "Enter A Nickname"
            textField.text = self.proxy.nickname
        })
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (action) -> Void in
            let nickname = alert.textFields![0].text
            let trim = nickname!.trimmingCharacters(in: NSCharacterSet(charactersIn: " ") as CharacterSet)
            if !(nickname != "" && trim == "") {
                self.api.setNickname(nickname!, for: self.proxy)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Table view delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return convos.count
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0: return CGFloat.leastNormalMagnitude
        case 1: return 15
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return "CONVERSATIONS"
        default: return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return 140
        case 1: return 80
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let dest = self.storyboard?.instantiateViewController(withIdentifier: Identifiers.ConvoViewController) as! ConvoViewController
            dest.convo = convos[tableView.indexPathForSelectedRow!.row]
            navigationController?.pushViewController(dest, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        
        // Proxy info
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.SenderProxyInfoCell, for: indexPath as IndexPath) as! SenderProxyInfoCell
            cell.nameLabel.text = proxy.name
            cell.nicknameButton.addTarget(self, action: #selector(ProxyInfoTableViewController.showEditNicknameAlert), for: .touchUpInside)
            cell.nicknameButton.setTitle(proxy.nickname == "" ? "Enter A Nickname" : proxy.nickname, for: .normal)
            cell.iconImageView.image = nil
            cell.iconImageView.kf.indicatorType = .activity
            api.getURL(forIconName: proxy.icon, completion: { (url) in
                cell.iconImageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: nil)
            })
            cell.changeIconButton.addTarget(self, action: #selector(ProxyInfoTableViewController.showIconPickerViewController), for: .touchUpInside)
            cell.selectionStyle = .none
            return cell
            
        // This proxy's convos
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.ConvoCell, for: indexPath as IndexPath) as! ConvoCell
            let convo = convos[indexPath.row]
            cell.iconImageView.image = nil
            cell.iconImageView.kf.indicatorType = .activity
            api.getURL(forIconName: convo.icon) { (url) in
                cell.iconImageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: nil)
            }
            cell.titleLabel.attributedText = api.getConvoTitle(receiverNickname: convo.receiverNickname, receiverName: convo.receiverProxyName, senderNickname: convo.senderNickname, senderName: convo.senderProxyName)
            cell.lastMessageLabel.text = convo.message
            cell.timestampLabel.text = convo.timestamp.toTimeAgo()
            cell.unreadLabel.text = convo.unread.toNumberLabel()
            return cell
            
        default: break
        }
        return UITableViewCell()
    }
    
    // MARK: - Select proxy view controller delegate
    func goToNewConvo(_ convo: Convo) {
        self.convo = convo
        shouldShowNewConvo = true
    }
}
