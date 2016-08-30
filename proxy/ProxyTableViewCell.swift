//
//  ProxyTableViewCell.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

class ProxyTableViewCell: UITableViewCell {
    
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var lastMessagePreviewLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var unreadMessageCountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}