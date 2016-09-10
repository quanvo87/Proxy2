//
//  IconPickerCell.swift
//  proxy
//
//  Created by Quan Vo on 9/9/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseStorage

class IconPickerCell: UICollectionViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconNameLabel: UILabel!
    
    let api = API.sharedInstance
    var icon = String() {
        didSet {
            // Set up
            layer.cornerRadius = 10
            
            // Set icon
            self.api.getURL(forIcon: icon) { (URL) in
                self.iconImageView.kf_setImageWithURL(NSURL(string: URL), placeholderImage: nil)
            }
            
            // Set name
            let index = icon.endIndex.advancedBy(-3)
            iconNameLabel.text = icon.substringToIndex(index)
        }
    }
}