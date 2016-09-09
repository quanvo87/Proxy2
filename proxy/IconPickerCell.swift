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
            setUp()
            setName()
            setIcon()
        }
    }
    
    func setUp() {
        layer.cornerRadius = 8
    }
    
    func setName() {
        let index = icon.endIndex.advancedBy(-3)
        iconNameLabel.text = icon.substringToIndex(index)
    }
    
    func setIcon() {
        if let iconURL = self.api.iconURLCache[icon] {
            iconImageView.kf_setImageWithURL(NSURL(string: iconURL), placeholderImage: nil)
        } else {
            let storageRef = FIRStorage.storage().referenceForURL(Constants.URLs.Storage)
            let starsRef = storageRef.child("\(icon).png")
            starsRef.downloadURLWithCompletion { (URL, error) -> Void in
                if error == nil {
                    self.api.iconURLCache[self.icon] = URL?.absoluteString
                    self.iconImageView.kf_setImageWithURL(NSURL(string: URL!.absoluteString)!, placeholderImage: nil)
                }
            }
        }
    }
}
