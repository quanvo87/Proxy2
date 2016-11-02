//
//  SelectSenderTableViewController.swift
//  proxy
//
//  Created by Quan Vo on 10/31/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class SelectSenderTableViewController: UITableViewController {

    let api = API.sharedInstance
    var proxies = [Proxy]()
    var selectSenderDelegate: SelectSenderDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Select Sender"
        
        let cancelButton = UIButton(type: .Custom)
        cancelButton.setImage(UIImage(named: "cancel"), forState: UIControlState.Normal)
        cancelButton.addTarget(self, action: #selector(SelectSenderTableViewController.cancel), forControlEvents: UIControlEvents.TouchUpInside)
        cancelButton.frame = CGRectMake(0, 0, 25, 25)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
        
        tableView.rowHeight = 60
        tableView.estimatedRowHeight = 60
        tableView.separatorStyle = .None
        
        FIRDatabase.database().reference().child(Path.Proxies).child(api.uid).queryOrderedByChild(Path.Timestamp).observeSingleEventOfType(.Value, withBlock: { snapshot in
            for child in snapshot.children {
                let proxy = Proxy(anyObject: child.value)
                self.proxies.append(proxy)
            }
            self.proxies = self.proxies.reverse()
            self.tableView.reloadData()
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        navigationItem.hidesBackButton = true
        tabBarController?.tabBar.hidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        tabBarController?.tabBar.hidden = false
    }
    
    func cancel() {
        navigationController?.popViewControllerAnimated(true)
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.min
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proxies.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.ProxyCell, forIndexPath: indexPath) as! ProxyCell
        let proxy = proxies[indexPath.row]
        
        // Set 'new' image
        cell.newImageView.hidden = true
        let secondsAgo = -NSDate(timeIntervalSince1970: proxy.created).timeIntervalSinceNow
        if secondsAgo < 60 * Settings.NewProxyIndicatorDuration {
            cell.newImageView.hidden = false
        }
        cell.contentView.bringSubviewToFront(cell.newImageView)
        
        // Set icon
        cell.iconImageView.image = nil
        cell.iconImageView.kf_indicatorType = .Activity
        api.getURL(forIcon: proxy.icon) { (url) in
            guard let url = url.absoluteString where url != "" else { return }
            cell.iconImageView.kf_setImageWithURL(NSURL(string: url), placeholderImage: nil)
        }
        
        cell.nameLabel.text = proxy.key
        cell.nicknameLabel.text = proxy.nickname
        cell.convoCountLabel.text = proxy.convos.toNumberLabel()
        cell.unreadLabel.text = proxy.unread.toNumberLabel()
        cell.accessoryType = .None
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let proxy = self.proxies[indexPath.row]
        selectSenderDelegate.setSender(proxy)
        navigationController?.popViewControllerAnimated(true)
    }
}
