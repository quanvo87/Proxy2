//
//  SenderPickerTableViewController.swift
//  proxy
//
//  Created by Quan Vo on 10/31/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class SenderPickerTableViewController: UITableViewController {

    let api = API.sharedInstance
    var proxies = [Proxy]()
    var senderPickerDelegate: SenderPickerDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Select Sender"
        
        let cancelButton = UIButton(type: .custom)
        cancelButton.addTarget(self, action: #selector(SenderPickerTableViewController.cancel), for: UIControlEvents.touchUpInside)
        cancelButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        cancelButton.setImage(UIImage(named: "cancel"), for: UIControlState.normal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
        
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
        
        api.ref.child(Path.Proxies).child(api.uid).queryOrdered(byChild: Path.Timestamp).observeSingleEvent(of: .value, with: { snapshot in
            for child in snapshot.children {
                guard let proxy = Proxy(anyObject: (child as AnyObject).value) else { return }
                self.proxies.append(proxy)
            }
            self.proxies = self.proxies.reversed()
            self.tableView.reloadData()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationItem.hidesBackButton = true
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        tabBarController?.tabBar.isHidden = false
    }
    
    func cancel() {
        _ = navigationController?.popViewController(animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proxies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.ProxyCell, for: indexPath as IndexPath) as! ProxyCell
        let proxy = proxies[indexPath.row]
        
        cell.newImageView.isHidden = true
        let secondsAgo = -Date(timeIntervalSince1970: proxy.created).timeIntervalSinceNow
        if secondsAgo < 60 * Settings.NewProxyIndicatorDuration {
            cell.newImageView.isHidden = false
            cell.contentView.bringSubview(toFront: cell.newImageView)
        }
        
        cell.iconImageView.image = nil
        cell.iconImageView.kf.indicatorType = .activity
        api.getURL(forIcon: proxy.icon) { (url) in
            guard let url = url else { return }
            cell.iconImageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: nil)
        }
        
        cell.nameLabel.text = proxy.key
        cell.nicknameLabel.text = proxy.nickname
        cell.convoCountLabel.text = proxy.convos.toNumberLabel()
        cell.unreadLabel.text = proxy.unread.toNumberLabel()
        cell.accessoryType = .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let proxy = proxies[indexPath.row]
        senderPickerDelegate.setSender(proxy)
        _ = navigationController?.popViewController(animated: true)
    }
}
