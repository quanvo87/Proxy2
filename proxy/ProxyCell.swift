//
//  ProxyCell.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseStorage

class ProxyCell: UITableViewCell {
    
    let api = API.sharedInstance
    
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!
    
    var proxy = Proxy() {
        didSet {
            accessoryType = .None
            
            if let iconURL = self.api.iconURLCache[proxy.icon] {
                iconImage.kf_setImageWithURL(NSURL(string: iconURL), placeholderImage: nil)
            } else {
                let storageRef = FIRStorage.storage().referenceForURL(Constants.URLs.Storage)
                let starsRef = storageRef.child("\(proxy.icon).png")
                starsRef.downloadURLWithCompletion { (URL, error) -> Void in
                    if error == nil {
                        self.api.iconURLCache[self.proxy.icon] = URL?.absoluteString
                        self.iconImage.kf_setImageWithURL(NSURL(string: URL!.absoluteString)!, placeholderImage: nil)
                    }
                }
            }
            
            nameLabel.text = proxy.key
            nicknameLabel.text = proxy.nickname
            unreadLabel.text = proxy.unread.unreadToUnreadLabel()
        }
    }
}