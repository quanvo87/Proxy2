//
//  HomeTableViewCell.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

class HomeTableViewCell: UITableViewCell {

    @IBOutlet weak var proxyNameLabel: UILabel!
    @IBOutlet weak var proxyNicknameLabel: UILabel!
    @IBOutlet weak var lastEventLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}