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
            nameLabel.text = proxy.key
            observeIcon()
            observeNickname()
        }
    }
    
    deinit {
        iconRef.removeObserverWithHandle(iconRefHandle)
        nicknameRef.removeObserverWithHandle(nicknameRefHandle)
    }
    
    func observeIcon() {
        iconRef = ref.child("proxies").child(proxy.owner).child(proxy.key).child("icon")
        iconRefHandle = iconRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let icon = snapshot.value as? String {
                self.api.getURL(forIcon: icon) { (URL) in
                    self.iconImageView.kf_setImageWithURL(NSURL(string: URL), placeholderImage: nil)
                }
            }
        })
    }
    
    func observeNickname() {
        nicknameRef = ref.child("proxies").child(proxy.owner).child(proxy.key).child("nickname")
        nicknameRefHandle = nicknameRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let nickname = snapshot.value as? String {
                if nickname != "" {
                    self.nicknameButton.setTitle(nickname, forState: .Normal)
                    return
                }
            }
            self.nicknameButton.setTitle("Enter A Nickname", forState: .Normal)
        })
    }
}
