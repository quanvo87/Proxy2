//
//  ConvoCell.swift
//  proxy
//
//  Created by Quan Vo on 9/9/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseStorage

class ConvoCell: UITableViewCell {
    
    let api = API.sharedInstance
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!
    
    var convo = Convo() {
        didSet{
            accessoryType = .None
            
            api.getURL(convo.icon) { (URL) in
                self.iconImageView.kf_setImageWithURL(NSURL(string: URL), placeholderImage: nil)
            }
            
            // extension to show title based on receiverProxy, convoNickname, senderProxy, and proxyNickname
            nameLabel.attributedText = toConvoTitle(convo.convoNickname, proxyNickname: convo.proxyNickname, you: convo.senderProxy, them: convo.receiverProxy, size: 14, navBar: false)
            
            messageLabel.text = convo.message
            timestampLabel.text = convo.timestamp.toTimeAgo()
            unreadLabel.text = convo.unread.toUnreadLabel()
        }
    }
    
}