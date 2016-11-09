//
//  BlockedUsersTableViewController.swift
//  proxy
//
//  Created by Quan Vo on 11/5/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class BlockedUsersTableViewController: UITableViewController {

    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var blockedUsersRef = FIRDatabaseReference()
    var blockedUsersRefHandle = FIRDatabaseHandle()
    var blockedUsers = [BlockedUser]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Blocked Users"
        
        let cancelButton = UIButton(type: .Custom)
        cancelButton.setImage(UIImage(named: "cancel"), forState: UIControlState.Normal)
        cancelButton.addTarget(self, action: #selector(BlockedUsersTableViewController.cancel), forControlEvents: UIControlEvents.TouchUpInside)
        cancelButton.frame = CGRectMake(0, 0, 25, 25)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
        
        tableView.rowHeight = 60
        tableView.estimatedRowHeight = 60
        
        blockedUsersRef = ref.child(Path.Blocked).child(api.uid)
        blockedUsersRefHandle = blockedUsersRef.queryOrderedByChild(Path.Created).observeEventType(.Value, withBlock: { (snapshot) in
            var blockedUsers = [BlockedUser]()
            for child in snapshot.children {
                if let blockedUser = BlockedUser(anyObject: child.value) {
                    blockedUsers.append(blockedUser)
                }
            }
            self.blockedUsers = blockedUsers.reverse()
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
    
    deinit {
        blockedUsersRef.removeObserverWithHandle(blockedUsersRefHandle)
    }
    
    func cancel() {
        navigationController?.popViewControllerAnimated(true)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedUsers.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let blockedUser = blockedUsers[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.BlockedUsersTableViewCell, forIndexPath: indexPath) as! BlockedUsersTableViewCell
        
        cell.selectionStyle = .None
        cell.accessoryType = .None
        cell.blockedUser = blockedUser
        
        cell.iconImageView.image = nil
        cell.iconImageView.kf_indicatorType = .Activity
        api.getURL(forIcon: blockedUser.icon) { (url) in
            guard let url = url else { return }
            cell.iconImageView.kf_setImageWithURL(url, placeholderImage: nil)
        }
        
        cell.nameLabel.text = blockedUser.name
        cell.nicknameLabel.text = blockedUser.nickname
        
        return cell
    }
}
