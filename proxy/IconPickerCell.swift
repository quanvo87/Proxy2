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
            layer.cornerRadius = 5
            iconImageView.kf_indicatorType = .Activity
            
            // Set icon
            api.getURL(forIcon: icon) { (url) in
                guard let url = url.absoluteString where url != "" else { return }
                self.iconImageView.kf_setImageWithURL(NSURL(string: url), placeholderImage: nil)
            }
            
            // Set name
            let index = icon.endIndex.advancedBy(-3)
            iconNameLabel.text = icon.substringToIndex(index)
        }
    }
}
