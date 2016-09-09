//
//  ProxyInfoHeaderCell.swift
//  proxy
//
//  Created by Quan Vo on 9/8/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase
import FirebaseStorage

class ProxyInfoHeaderCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var editIconButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameButton: UIButton!
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var iconRef = FIRDatabaseReference()
    var iconRefHandle = FIRDatabaseHandle()
    var nicknameRef = FIRDatabaseReference()
    var nicknameRefHandle = FIRDatabaseHandle()
    var proxy = Proxy() {
        didSet {
            setUp()
            observeIcon()
            observeNickname()
            nameLabel.text = proxy.key
        }
    }
    
    deinit {
        iconRef.removeObserverWithHandle(iconRefHandle)
        nicknameRef.removeObserverWithHandle(nicknameRefHandle)
    }
    
    func setUp() {
        nicknameButton.titleLabel?.adjustsFontSizeToFitWidth = true
        nicknameButton.titleLabel?.minimumScaleFactor = 0.75
    }
    
    // MARK: - Database
    func observeIcon() {
        iconRef = ref.child("proxies").child(proxy.owner).child(proxy.key).child("icon")
        iconRefHandle = iconRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let icon = snapshot.value as? String {
                self.setIcon(icon)
            }
        })
    }
    
    func observeNickname() {
        nicknameRef = ref.child("proxies").child(proxy.owner).child(proxy.key).child("nickname")
        nicknameRefHandle = nicknameRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let nickname = snapshot.value as? String where nickname != "" {
                self.nicknameButton.setTitle(nickname, forState: .Normal)
            } else {
                self.nicknameButton.setTitle("Enter A Nickname", forState: .Normal)
            }
        })
    }
    
    func setIcon(icon: String) {
        if let iconURL = self.api.iconURLCache[icon] {
            iconImageView.kf_setImageWithURL(NSURL(string: iconURL), placeholderImage: nil)
        } else {
            let storageRef = FIRStorage.storage().referenceForURL(Constants.URLs.Storage)
            let starsRef = storageRef.child("\(icon).png")
            starsRef.downloadURLWithCompletion { (URL, error) -> Void in
                if error == nil {
                    self.api.iconURLCache[icon] = URL?.absoluteString
                    self.iconImageView.kf_setImageWithURL(NSURL(string: URL!.absoluteString)!, placeholderImage: nil)
                }
            }
        }
    }
}