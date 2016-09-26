//
//  SenderProxyInfoCell.swift
//  proxy
//
//  Created by Quan Vo on 9/8/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase
import FirebaseStorage

class SenderProxyInfoCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var changeIconButton: UIButton!
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
            selectionStyle = .None
            iconImageView.kf_indicatorType = .Activity
            nameLabel.text = proxy.key
            removeObservers()
            observeIcon()
            observeNickname()
        }
    }
    
    deinit {
        iconRef.removeObserverWithHandle(iconRefHandle)
        nicknameRef.removeObserverWithHandle(nicknameRefHandle)
    }
    
    func removeObservers() {
        iconRef.removeObserverWithHandle(iconRefHandle)
        nicknameRef.removeObserverWithHandle(nicknameRefHandle)
    }
    
    func observeIcon() {
        iconRef = ref.child(Path.Icon).child(proxy.key).child(Path.Icon)
        iconRefHandle = iconRef.observeEventType(.Value, withBlock: { (snapshot) in
            guard let icon = snapshot.value as? String where icon != "" else { return }
            self.api.getURL(forIcon: icon) { (url) in
                guard let url = url.absoluteString where url != "" else { return }
                self.iconImageView.kf_setImageWithURL(NSURL(string: url), placeholderImage: nil)
            }
        })
    }
    
    func observeNickname() {
        nicknameRef = ref.child(Path.Nickname).child(proxy.key).child(Path.Nickname)
        nicknameRefHandle = nicknameRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let nickname = snapshot.value as? String where nickname != "" {
                self.nicknameButton.setTitle(nickname, forState: .Normal)
            } else {
                self.nicknameButton.setTitle("Enter A Nickname", forState: .Normal)
            }
        })
    }
}
