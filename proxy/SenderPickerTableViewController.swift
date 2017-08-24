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
        
        api.ref.child(Path.Proxies).child(api.uid).queryOrdered(byChild: Path.Timestamp).observeSingleEvent(of: .value, with: { data in
            for child in data.children {
                if let proxy = Proxy((child as! DataSnapshot).value as AnyObject) {
                    self.proxies.append(proxy)
                }
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
    
    @objc func cancel() {
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
        let secondsAgo = -Date(timeIntervalSince1970: proxy.dateCreated).timeIntervalSinceNow
        if secondsAgo < 60 * Settings.NewProxyIndicatorDuration {
            cell.newImageView.isHidden = false
            cell.contentView.bringSubview(toFront: cell.newImageView)
        }
        
        cell.iconImageView.image = nil
//        cell.iconImageView.kf.indicatorType = .activity
        api.getURL(forIconName: proxy.icon) { (url) in
//            cell.iconImageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: nil)
        }
        
        cell.nameLabel.text = proxy.name
        cell.nicknameLabel.text = proxy.nickname
        cell.convoCountLabel.text = proxy.convoCount.asLabel
        cell.unreadLabel.text = proxy.unreadCount.asLabel
        cell.accessoryType = .none
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let proxy = proxies[indexPath.row]
        senderPickerDelegate.setSender(to: proxy)
        _ = navigationController?.popViewController(animated: true)
    }
}
