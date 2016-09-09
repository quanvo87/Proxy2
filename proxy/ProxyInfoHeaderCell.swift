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
    var nicknameRef = FIRDatabaseReference()
    var nicknameRefHandle = FIRDatabaseHandle()
    var proxy = Proxy() {
        didSet {
            observeNickname()
            nameLabel.text = proxy.key
            setIcon()
        }
    }
    
    deinit {
        nicknameRef.removeObserverWithHandle(nicknameRefHandle)
    }
    
    func setIcon() {
        if let iconURL = self.api.iconURLCache[proxy.icon] {
            iconImageView.kf_setImageWithURL(NSURL(string: iconURL), placeholderImage: nil)
        } else {
            let storageRef = FIRStorage.storage().referenceForURL(Constants.URLs.Storage)
            let starsRef = storageRef.child("\(proxy.icon).png")
            starsRef.downloadURLWithCompletion { (URL, error) -> Void in
                if error == nil {
                    self.api.iconURLCache[self.proxy.icon] = URL?.absoluteString
                    self.iconImageView.kf_setImageWithURL(NSURL(string: URL!.absoluteString)!, placeholderImage: nil)
                }
            }
        }
    }
    
    // MARK: - Database
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
}