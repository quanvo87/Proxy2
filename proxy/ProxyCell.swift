//
//  ProxyCell.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase
import FirebaseStorage

class ProxyCell: UITableViewCell {
    
    @IBOutlet weak var newImageView: UIImageView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    
    var iconRef = FIRDatabaseReference()
    var iconRefHandle = FIRDatabaseHandle()
    
    var nicknameRef = FIRDatabaseReference()
    var nicknameRefHandle = FIRDatabaseHandle()
    
    var unreadRef = FIRDatabaseReference()
    var unreadRefHandle = FIRDatabaseHandle()
    
    var proxy = Proxy() {
        didSet {
            // Set up
            accessoryType = .DisclosureIndicator
            
            // Set up 'new proxy' indicator image
            newImageView.hidden = true
            let secondsAgo = -NSDate(timeIntervalSince1970: proxy.timeCreated).timeIntervalSinceNow
            if secondsAgo < 60 * Settings.NewProxyIndicatorDuration {
                newImageView.hidden = false
            }
            
            // Set labels
            nameLabel.text = proxy.key
            nicknameLabel.text = ""
            unreadLabel.text = ""
            
            // Observe dynamic values
            observeIcon()
            observeNickname()
            observeUnread()
        }
    }
    
    deinit {
        iconRef.removeObserverWithHandle(iconRefHandle)
        nicknameRef.removeObserverWithHandle(nicknameRefHandle)
        unreadRef.removeObserverWithHandle(unreadRefHandle)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        nameLabel.text = ""
        nicknameLabel.text = ""
        unreadLabel.text = ""
        iconRef.removeObserverWithHandle(iconRefHandle)
        nicknameRef.removeObserverWithHandle(nicknameRefHandle)
        unreadRef.removeObserverWithHandle(unreadRefHandle)
    }
    
    func observeIcon() {
        iconRef = ref.child(Path.Icon).child(proxy.key)
        iconRefHandle = iconRef.observeEventType(.Value, withBlock: { (snapshot) in
            guard let icon = snapshot.value as? String where icon != "" else { return }
            self.api.getURL(forIcon: icon) { (url) in
                guard let url = url.absoluteString where url != "" else { return }
                self.iconImageView.kf_indicatorType = .Activity
                self.iconImageView.kf_setImageWithURL(NSURL(string: url), placeholderImage: nil)
            }
        })
    }
    
    func observeNickname() {
        nicknameRef = ref.child(Path.Nickname).child(proxy.key)
        nicknameRefHandle = nicknameRef.observeEventType(.Value, withBlock: { (snapshot) in
            guard let nickname = snapshot.value as? String else { return }
            self.nicknameLabel.text = nickname
        })
    }
    
    func observeUnread() {
//        unreadRef = ref.child(Path.Unread).child(convo.senderId).child(convo.key)
//        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { (snapshot) in
//            guard let unread = snapshot.value as? Int else { return }
//            self.unreadLabel.text = unread.toUnreadLabel()
//        })
    }
}
