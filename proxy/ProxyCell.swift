//
//  ProxyCell.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseStorage

class ProxyCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!
    
    let api = API.sharedInstance
    var proxy = Proxy() {
        didSet {
            // Set up
            accessoryType = .None
            
            // Set image
            api.getURL(forIcon: proxy.icon) { (URL) in
                self.iconImageView.kf_setImageWithURL(NSURL(string: URL), placeholderImage: nil)
            }
            
            // Set labels
            nameLabel.text = proxy.key
            nicknameLabel.text = proxy.nickname
            unreadLabel.text = proxy.unread.toUnreadLabel()
        }
    }
}