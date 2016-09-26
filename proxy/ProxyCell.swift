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
    @IBOutlet weak var convoCountLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    
    var iconRef = FIRDatabaseReference()
    var iconRefHandle = FIRDatabaseHandle()
    
    var nicknameRef = FIRDatabaseReference()
    var nicknameRefHandle = FIRDatabaseHandle()
    
    var convoCountRef = FIRDatabaseReference()
    var convoCountRefHandle = FIRDatabaseHandle()
    
    var unreadRef = FIRDatabaseReference()
    var unreadRefHandle = FIRDatabaseHandle()
    
    var proxy = Proxy() {
        didSet {
            // Set up
            iconImageView.kf_indicatorType = .Activity
            nameLabel.text = proxy.key
            nicknameLabel.text = ""
            convoCountLabel.text = ""
            unreadLabel.text = ""
            
            // Set up 'new proxy' indicator image
            newImageView.hidden = true
            let secondsAgo = -NSDate(timeIntervalSince1970: proxy.timeCreated).timeIntervalSinceNow
            if secondsAgo < 60 * Settings.NewProxyIndicatorDuration {
                newImageView.hidden = false
            }
            
            // Observe dynamic values
            observeIcon()
            observeNickname()
            observeConvoCount()
            observeUnread()
        }
    }
    
    deinit {
        iconRef.removeObserverWithHandle(iconRefHandle)
        nicknameRef.removeObserverWithHandle(nicknameRefHandle)
        convoCountRef.removeObserverWithHandle(convoCountRefHandle)
        unreadRef.removeObserverWithHandle(unreadRefHandle)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconRef.removeObserverWithHandle(iconRefHandle)
        nicknameRef.removeObserverWithHandle(nicknameRefHandle)
        convoCountRef.removeObserverWithHandle(convoCountRefHandle)
        unreadRef.removeObserverWithHandle(unreadRefHandle)
    }
    
    func observeIcon() {
        iconRef = ref.child(Path.Icon).child(proxy.key).child(Path.Icon)
        iconRefHandle = iconRef.observeEventType(.Value, withBlock: { (snapshot) in
            guard let icon = snapshot.value as? String where icon != "" else { return }
            self.api.getURL(forIcon: icon) { (url) in
                guard let url = url.absoluteString where url != "" else { return }
                self.iconImageView.image = nil
                self.iconImageView.kf_setImageWithURL(NSURL(string: url), placeholderImage: nil)
            }
        })
    }
    
    func observeNickname() {
        nicknameRef = ref.child(Path.Nickname).child(proxy.key).child(Path.Nickname)
        nicknameRefHandle = nicknameRef.observeEventType(.Value, withBlock: { (snapshot) in
            guard let nickname = snapshot.value as? String else { return }
            self.nicknameLabel.text = nickname
        })
    }
    
    func observeConvoCount() {
        convoCountRef = ref.child(Path.Convos).child(proxy.key)
        convoCountRefHandle = convoCountRef.observeEventType(.Value, withBlock: { (snapshot) in
            var count = 0
            for child in snapshot.children {
                let convo = Convo(anyObject: child.value)
                if !convo.didLeaveConvo {
                    count += 1
                }
            }
            self.convoCountLabel.text = count == 0 ? "" : String(count)
        })
    }
    
    func observeUnread() {
        unreadRef = ref.child(Path.Unread).child(api.uid).child(proxy.key)
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { (snapshot) in
            var unread = 0
            for convo in snapshot.children {
                let convo = convo as! FIRDataSnapshot
                unread += convo.value as! Int
            }
            self.unreadLabel.text = unread.toUnreadLabel()
        })

    }
}
