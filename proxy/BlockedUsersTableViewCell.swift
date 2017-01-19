//
//  BlockedUsersTableViewCell.swift
//  proxy
//
//  Created by Quan Vo on 11/5/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class BlockedUsersTableViewCell: UITableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    
    let api = API.sharedInstance
    var blockedUser: BlockedUser?
    
    @IBAction func unblock(_ sender: AnyObject) {
        if let blockedUser = blockedUser {
            api.unblockUser(blockedUser.id)
        }
    }
}
