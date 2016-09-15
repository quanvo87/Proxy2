//
//  ConvoCell.swift
//  proxy
//
//  Created by Quan Vo on 9/9/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseStorage

class ConvoCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!
    
    let api = API.sharedInstance
    var convo = Convo() {
        didSet{
            // Set up
            accessoryType = .None
            
            // Set icon
            api.getURL(forIcon: convo.icon) { (URL) in
                self.iconImageView.kf_setImageWithURL(NSURL(string: URL), placeholderImage: nil)
            }
            
            // Set labels
            nameLabel.attributedText = getConvoTitle(convo.receiverNickname, senderNickname: convo.senderNickname, you: convo.senderProxy, them: convo.receiverProxy, size: 14, navBar: false)
            messageLabel.text = convo.message
            timestampLabel.text = convo.timestamp.toTimeAgo()
            unreadLabel.text = convo.unread.toUnreadLabel()
        }
    }
}